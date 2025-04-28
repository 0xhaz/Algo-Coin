// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPoolStore} from "../interfaces/IPoolStore.sol";
import {IPoolStoreGov} from "../interfaces/IPoolStoreGov.sol";
import {ICurve} from "../interfaces/ICurve.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {Operator} from "../access/Operator.sol";

/**
 * @title Feeder
 * @notice This contract is responsible to adjust the weights of LP depending on whether the token is above or below the peg.
 * @dev It depends on the oracle to get the price of the token and the curve to calculate the ceiling.
 * @dev If the token price < 1.0 ETH -> token is below peg
 * @dev If the token price > 1.0 ETH -> token is above peg
 */
contract Feeder is Operator {
    using Math for uint256;

    enum FeedStatus {
        Neutral,
        BelowPeg,
        AbovePeg
    }

    uint256 private constant CORE_POOL_TOTAL_WEIGHT = 60e18;
    uint256 private constant SHARE_POOL_FIXED_WEIGHT = 10e18;
    uint256 private constant PRECISION = 1e18;

    // Below peg
    uint256 private constant BOARDROOM_WEIGHT_BELOW_PEG = 15e18;
    uint256 private constant BONDROOM_WEIGHT_BELOW_PEG = 5e18;
    uint256 private constant STRATEGIC_PAIR_WEIGHT_BELOW_PEG = 5e18;
    uint256 private constant COMMUNITY_FUND_WEIGHT_BELOW_PEG = 5e18;

    // Above peg
    uint256 private constant BOARDROOM_WEIGHT_ABOVE_PEG = 5e18;
    uint256 private constant STRATEGIC_PAIR_WEIGHT_ABOVE_PEG = 10e18;
    uint256 private constant COMMUNITY_FUND_WEIGHT_ABOVE_PEG = 15e18;

    address private token;
    address private target;
    address private curve;
    address private oracle;

    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function setTarget(address _newTarget) external onlyOwner {
        target = _newTarget;
    }

    function setCurve(address _curve) external onlyOwner {
        curve = _curve;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    uint256 cashLP;
    uint256 cashVault;
    uint256 shareLP;
    uint256 boardroom;
    uint256 bondroom;
    uint256 strategicPair;
    uint256 communityFund;

    FeedStatus lastUpdated = FeedStatus.Neutral;

    function feed() public onlyOperator {
        uint256 price = IOracle(oracle).consult(token, PRECISION);
        uint256 rate = ICurve(curve).calcCeiling(price);

        IPoolStoreGov(target).setPool(cashLP, CORE_POOL_TOTAL_WEIGHT - rate);
        IPoolStoreGov(target).setPool(cashVault, rate);
        if (IPoolStore(target).weightOf(shareLP) != SHARE_POOL_FIXED_WEIGHT) {
            IPoolStoreGov(target).setPool(shareLP, SHARE_POOL_FIXED_WEIGHT);
        }

        /*
         * If the price is below peg, we want to set the weights to:
         * - Boardroom: 15%
         * - Bondroom: 10%
         * - StrategicPair: 10%
         * - CommunityFund: 10%
         */
        if (lastUpdated != FeedStatus.BelowPeg && price < PRECISION) {
            lastUpdated = FeedStatus.BelowPeg;
            _setBelowPegWeights();
        }

        if (lastUpdated != FeedStatus.AbovePeg && price >= PRECISION) {
            lastUpdated = FeedStatus.AbovePeg;
            _setAbovePegWeights();
        }
    }

    function _setBelowPegWeights() private {
        IPoolStoreGov(target).setPool(boardroom, BOARDROOM_WEIGHT_BELOW_PEG);
        IPoolStoreGov(target).setPool(bondroom, BONDROOM_WEIGHT_BELOW_PEG);
        IPoolStoreGov(target).setPool(strategicPair, STRATEGIC_PAIR_WEIGHT_BELOW_PEG);
        IPoolStoreGov(target).setPool(communityFund, COMMUNITY_FUND_WEIGHT_BELOW_PEG);
    }

    function _setAbovePegWeights() private {
        IPoolStoreGov(target).setPool(boardroom, BOARDROOM_WEIGHT_ABOVE_PEG);
        IPoolStoreGov(target).setPool(strategicPair, STRATEGIC_PAIR_WEIGHT_ABOVE_PEG);
        IPoolStoreGov(target).setPool(communityFund, COMMUNITY_FUND_WEIGHT_ABOVE_PEG);
    }
}
