// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Operator} from "../access/Operator.sol";

contract Epoch is Operator {
    using Math for uint256;

    /*////////////////////////////////////////////////////////////
                            EVENTS
    ////////////////////////////////////////////////////////////*/
    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);

    /*////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    ////////////////////////////////////////////////////////////*/

    error Epoch__InvalidStartTime();
    error Epoch__NotStartedYet();
    error Epoch__NotAllowed();

    /*///////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////*/

    uint256 private period;
    uint256 private startTime;
    uint256 private lastExecutedAt;

    /*////////////////////////////////////////////////////////////
                            MODIFIERS
    ////////////////////////////////////////////////////////////*/

    modifier checkStartTime() {
        if (block.timestamp <= startTime) revert Epoch__NotStartedYet();
        _;
    }

    modifier checkEpoch() {
        if (block.timestamp < startTime) revert Epoch__NotStartedYet();
        if (!callable()) revert Epoch__NotAllowed();
        _;

        lastExecutedAt = block.timestamp;
    }

    /*////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ////////////////////////////////////////////////////////////*/
    constructor(uint256 _period, uint256 _startTime, uint256 _startEpoch) {
        if (_startTime < block.timestamp) revert Epoch__InvalidStartTime();
        period = _period;
        startTime = _startTime;
        lastExecutedAt = _startTime + _startEpoch * _period;
    }

    /*////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ////////////////////////////////////////////////////////////*/
    function callable() public view returns (bool) {
        return getCurrentEpoch() >= getNextEpoch();
    }

    function getLastEpoch() public view returns (uint256) {
        return (lastExecutedAt - startTime) / period;
    }

    function getCurrentEpoch() public view returns (uint256) {
        return (Math.max(startTime, block.timestamp) - startTime) / period;
    }

    function getNextEpoch() public view returns (uint256) {
        // if (startTime == lastExecutedAt) return 0;

        return getLastEpoch() + 1;
    }

    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    /*///////////////////////////////////////////////////////////
                            GOVERNANCE
    //////////////////////////////////////////////////////////*/

    function setPeriod(uint256 _period) external onlyOperator {
        period = _period;
    }

    function poke() external checkEpoch {}
}
