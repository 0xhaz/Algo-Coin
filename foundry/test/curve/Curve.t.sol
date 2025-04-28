// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {LinearThreshold} from "src/curve/Linear.sol";
import {Sigmoid} from "src/curve/Sigmoid.sol";
import {BIP11} from "src/curve/BIP11.sol";

contract CurveTest is Test {
    LinearThreshold public linear;
    Sigmoid public sigmoid;
    BIP11 public bip11;

    uint256 constant MIN_SUPPLY = 1e18;
    uint256 constant MAX_SUPPLY = 100e18;
    uint256 constant MIN_CEILING = 1e17;
    uint256 constant MAX_CEILING = 1e18;

    function setUp() public {
        linear = new LinearThreshold(MIN_SUPPLY, MAX_SUPPLY, MIN_CEILING, MAX_CEILING);
        sigmoid = new Sigmoid(MIN_SUPPLY, MAX_SUPPLY, MIN_CEILING, MAX_CEILING);
        bip11 = new BIP11(MIN_SUPPLY, MAX_SUPPLY, MIN_CEILING, MAX_CEILING);
    }

    function test_LinearThresholdBehavior() public view {
        // Test across different supply ranges
        for (uint256 supply = 0; supply <= 120e18; supply += 20e18) {
            uint256 ceiling = linear.calcCeiling(supply);
            console.log("Supply:", supply / 1e18, "=> Ceiling: ", ceiling / 1e18);
        }
    }

    function test_SigmoidThresholdBehavior() public view {
        // Test across different supply ranges
        for (uint256 supply = 0; supply <= 120e18; supply += 20e18) {
            uint256 ceiling = sigmoid.calcCeiling(supply);
            console.log("Supply:", supply / 1e18, "=> Ceiling: ", ceiling / 1e18);
        }
    }

    function test_BIP11Behavior() public view {
        // Test across different supply ranges
        for (uint256 price = 0; price <= 120e18; price += 20e18) {
            uint256 ceiling = bip11.calcCeiling(price);
            console.log("Price:", price / 1e18, "=> Ceiling: ", ceiling / 1e18);
        }
    }

    function test_Governance() public {
        linear.setMinSupply(5e18);
        linear.setMaxSupply(200e18);
        linear.setMinCeiling(5e17);
        linear.setMaxCeiling(2e18);

        assertEq(linear.minSupply(), 5e18);
        assertEq(linear.maxSupply(), 200e18);
        assertEq(linear.minCeiling(), 5e17);
        assertEq(linear.maxCeiling(), 2e18);

        sigmoid.setMinSupply(5e18);
        sigmoid.setMaxSupply(200e18);
        sigmoid.setMinCeiling(5e17);
        sigmoid.setMaxCeiling(2e18);

        assertEq(sigmoid.minSupply(), 5e18);
        assertEq(sigmoid.maxSupply(), 200e18);
        assertEq(sigmoid.minCeiling(), 5e17);
        assertEq(sigmoid.maxCeiling(), 2e18);

        bip11.setMinSupply(5e18);
        bip11.setMaxSupply(200e18);
        bip11.setMinCeiling(5e17);
        bip11.setMaxCeiling(2e18);

        assertEq(bip11.minSupply(), 5e18);
        assertEq(bip11.maxSupply(), 200e18);
        assertEq(bip11.minCeiling(), 5e17);
        assertEq(bip11.maxCeiling(), 2e18);
    }
}
