// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Operator} from "src/access/Operator.sol";
import {Epoch} from "src/utils/Epoch.sol";
import {IBasisAsset} from "src/interfaces/IBasisAsset.sol";

abstract contract TresuryState is Epoch {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error Treasury__Initialized();
    error Treasury__NotOperator();
    error Treasury__NotInitialized();
    error Treasury__NotMigrated();
    error Treasury__Migrated();
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Initialized(address indexed executor, uint256 at);
    event Migration(address indexed target);

    /*//////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    bool public migrated = false;
    bool public initialized = false;

    address public cash;
    address public bond;
    address public share;

    address public fund;
    address public curve;

    address public bOracle;
    address public sOracle;
    address public seigniorageProxy;

    uint256 public cashPriceOne;

    uint256 public lastBondOracleEpoch;
    uint256 public bondCap;
    uint256 public accumulatedSeigniorage;
    uint256 public fundAllocation = 2;

    modifier checkOperator() {
        if (
            IBasisAsset(cash).operator() != address(this) && IBasisAsset(bond).operator() != address(this)
                && IBasisAsset(share).operator() != address(this)
        ) revert Treasury__NotOperator();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                GOVERNANCE
    //////////////////////////////////////////////////////////////*/
    function initialize() public checkOperator {
        if (initialized) revert Treasury__Initialized();

        accumulatedSeigniorage = IERC20(cash).balanceOf(address(this));
        initialized = true;
        emit Initialized(msg.sender, block.timestamp);
    }

    function migrate(address target) public onlyOperator checkOperator {
        if (migrated) revert Treasury__Migrated();

        Operator(cash).transferOperator(target);
        Operator(cash).transferOwnership(target);
        IERC20(cash).transfer(target, IERC20(cash).balanceOf(address(this)));

        Operator(bond).transferOperator(target);
        Operator(bond).transferOwnership(target);
        IERC20(bond).transfer(target, IERC20(bond).balanceOf(address(this)));

        Operator(share).transferOperator(target);
        Operator(share).transferOwnership(target);
        IERC20(share).transfer(target, IERC20(share).balanceOf(address(this)));

        migrated = true;
        emit Migration(target);
    }

    function setFund(address _newFund) public onlyOperator {
        fund = _newFund;
    }

    function setCeilingCurve(address _newCeilingCurve) public onlyOperator {
        curve = _newCeilingCurve;
    }

    function setBondOracle(address _bondOracle) public onlyOperator {
        bOracle = _bondOracle;
    }

    function setSeigniorageOracle(address _seigniorageOracle) public onlyOperator {
        sOracle = _seigniorageOracle;
    }

    function setSeigniorageProxy(address _seigniorageProxy) public onlyOperator {
        seigniorageProxy = _seigniorageProxy;
    }

    function setFundAllocationRate(uint256 _fundAllocation) public onlyOperator {
        fundAllocation = _fundAllocation;
    }
}
