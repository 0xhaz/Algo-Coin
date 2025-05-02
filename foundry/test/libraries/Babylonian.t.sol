// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Babylonian} from "src/libraries/Babylonian.sol";
import {Test, console} from "forge-std/Test.sol";

contract BabylonianTest is Test {
    function test_Sqrt() public pure {
        assertEq(Babylonian.sqrt(0), 0);
        assertEq(Babylonian.sqrt(1), 1);
        assertEq(Babylonian.sqrt(2), 1);
        assertEq(Babylonian.sqrt(3), 1);
        assertEq(Babylonian.sqrt(4), 2);
        assertEq(Babylonian.sqrt(5), 2);
        assertEq(Babylonian.sqrt(6), 2);
        assertEq(Babylonian.sqrt(7), 2);
        assertEq(Babylonian.sqrt(8), 2);
        assertEq(Babylonian.sqrt(9), 3);
    }
}
