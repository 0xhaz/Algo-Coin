// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Curve} from "src/curve/Curve.sol";

contract MockCurve is Curve {
    uint256 public ceiling;

    constructor(uint256 _ceiling, uint256 _minSupply, uint256 _maxSupply, uint256 _minCeiling, uint256 _maxCeiling) {
        ceiling = _ceiling;
        minSupply = _minSupply;
        maxSupply = _maxSupply;
        minCeiling = _minCeiling;
        maxCeiling = _maxCeiling;
    }

    function setCeiling(uint256 _ceiling) external {
        ceiling = _ceiling;
    }

    function calcCeiling(uint256) external view override returns (uint256) {
        return ceiling;
    }
}
