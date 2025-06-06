// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ICurve} from "src/interfaces/ICurve.sol";
import {IOracle} from "src/interfaces/IOracle.sol";
import {IBasisAsset} from "src/interfaces/IBasisAsset.sol";
import {Babylonian} from "src/libraries/Babylonian.sol";
import {Operator} from "src/access/Operator.sol";
import {Epoch} from "src/utils/Epoch.sol";
import {SeigniorageProxy} from "src/treasury/SeigniorageProxy.sol";
import {TreasuryState} from "src/treasury/TreasuryState.sol";
import {ContractGuard} from "src/utils/ContractGuard.sol";
import {ISimpleERCFund} from "src/interfaces/ISimpleERCFund.sol";

/**
 * @title Basis Cash Treasury
 * @notice Monetary policy logic to adjust supplies of basis cash assets
 *
 */
contract Treasury is TreasuryState, ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    /*//////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 private constant PRECISION = 1e18;

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier checkMigration() {
        if (migrated) revert Treasury__Migrated();
        _;
    }

    modifier updatePrice() {
        _;

        _updateCashPrice();
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _cash,
        address _bond,
        address _share,
        address _bOracle,
        address _sOracle,
        address _seigniorageProxy,
        address _fund,
        address _curve,
        uint256 _startTime
    ) Epoch(1 days, _startTime, 0) {
        cash = _cash;
        bond = _bond;
        share = _share;
        curve = _curve;
        bOracle = _bOracle;
        sOracle = _sOracle;
        seigniorageProxy = _seigniorageProxy;

        fund = _fund;

        cashPriceOne = PRECISION;
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getReserve() public view returns (uint256) {
        return accumulatedSeigniorage;
    }

    function circulatingSupply() public view returns (uint256) {
        return IERC20(cash).totalSupply() - accumulatedSeigniorage;
    }

    function getCeilingPrice() public view returns (uint256) {
        return ICurve(curve).calcCeiling(circulatingSupply());
    }

    function getBondOraclePrice() public view returns (uint256) {
        return _getCashPrice(bOracle);
    }

    function getSeigniorageOraclePrce() public view returns (uint256) {
        return _getCashPrice(sOracle);
    }

    function _getCashPrice(address oracle) internal view returns (uint256) {
        try IOracle(oracle).consult(cash, PRECISION) returns (uint256 price) {
            return price;
        } catch {
            revert Treasury__OracleError();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _updateConversionLimit(uint256 cashPrice) internal {
        uint256 currentEpoch = Epoch(bOracle).getLastEpoch();
        if (lastBondOracleEpoch != currentEpoch) {
            uint256 percentage = cashPriceOne - cashPrice;
            uint256 bondSupply = IERC20(bond).totalSupply();

            bondCap = (circulatingSupply() * percentage) / PRECISION;
            bondCap = bondCap - (Math.min(bondCap, bondSupply));

            lastBondOracleEpoch = currentEpoch;
        }
    }

    function _updateCashPrice() internal {
        if (Epoch(bOracle).callable()) {
            try IOracle(bOracle).update() {} catch {}
        }
        if (Epoch(sOracle).callable()) {
            try IOracle(sOracle).update() {} catch {}
        }
    }

    function buyBonds(uint256 amount, uint256 targetPrice)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
        updatePrice
    {
        if (amount <= 0) revert Treasury__ZeroAmount();
        uint256 cashPrice = _getCashPrice(bOracle);
        if (cashPrice >= targetPrice) revert Treasury__CashPriceMoved();
        if (cashPrice > cashPriceOne) revert Treasury__CashPriceNotEligibleForBondPurchase();

        _updateConversionLimit(cashPrice);

        amount = Math.min(amount, (bondCap * cashPrice) / PRECISION);
        if (amount <= 0) revert Treasury__AmountExceedsBondCap();

        IBasisAsset(cash).burnFrom(_msgSender(), amount);
        IBasisAsset(bond).mint(_msgSender(), (amount * PRECISION) / cashPrice);

        emit BoughtBonds(_msgSender(), amount);
    }

    function redeemBonds(uint256 amount)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
        updatePrice
    {
        if (amount <= 0) revert Treasury__ZeroAmount();

        uint256 cashPrice = _getCashPrice(bOracle);
        if (cashPrice < getCeilingPrice()) revert Treasury__CashPriceNotEligibleForBondPurchase();
        if (IERC20(cash).balanceOf(address(this)) <= amount) revert Treasury__NoMoreBudget();

        accumulatedSeigniorage = accumulatedSeigniorage - (Math.min(accumulatedSeigniorage, amount));

        IBasisAsset(bond).burnFrom(_msgSender(), amount);
        IERC20(cash).safeTransfer(_msgSender(), amount);

        emit RedeemedBonds(_msgSender(), amount);
    }

    function allocateSeigniorage() external onlyOneBlock checkMigration checkStartTime checkEpoch checkOperator {
        _updateCashPrice();
        uint256 cashPrice = _getCashPrice(sOracle);
        if (cashPrice <= getCeilingPrice()) return;

        uint256 percentage = cashPrice - cashPriceOne;
        uint256 seigniorage = (circulatingSupply() * percentage) / PRECISION;
        IBasisAsset(cash).mint(address(this), seigniorage);

        uint256 fundReserve = (seigniorage * fundAllocation) / 100;
        if (fundReserve > 0) {
            IERC20(cash).safeIncreaseAllowance(fund, fundReserve);
            ISimpleERCFund(fund).deposit(cash, fundReserve, "Treasury: Seigniorage Allocation");

            emit FundedToCommunityFund(block.timestamp, fundReserve);
        }

        seigniorage = seigniorage - fundReserve;

        uint256 treasuryReserve = Math.min(seigniorage, IERC20(bond).totalSupply() - accumulatedSeigniorage);
        if (treasuryReserve > 0) {
            if (treasuryReserve == seigniorage) {
                treasuryReserve = treasuryReserve * 80 / 100;
            }
            accumulatedSeigniorage = accumulatedSeigniorage + treasuryReserve;

            emit TreasuryFunded(block.timestamp, treasuryReserve);
        }

        seigniorage = seigniorage - treasuryReserve;
        if (seigniorage > 0) {
            IERC20(cash).safeIncreaseAllowance(seigniorageProxy, seigniorage);
            SeigniorageProxy(seigniorageProxy).allocateSeigniorage(seigniorage);

            emit SeigniorageDistributed(block.timestamp, seigniorage);
        }
    }
}
