// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Safe112} from "src/libraries/Safe112.sol";

contract Safe112Test is Test {
    using Safe112 for uint256;

    function testAdd() public pure {
        uint256 a = 10;
        uint256 b = 20;
        uint256 result = Safe112.add(uint112(a), uint112(b));
        console.log("Add result:", result);
        assertEq(result, 30);
    }

    function testSub() public pure {
        uint256 a = 30;
        uint256 b = 20;
        uint256 result = Safe112.sub(uint112(a), uint112(b));
        console.log("Sub result:", result);
        assertEq(result, 10);
    }

    function testMul() public pure {
        uint256 a = 10;
        uint256 b = 20;
        uint256 result = Safe112.mul(uint112(a), uint112(b));
        console.log("Mul result:", result);
        assertEq(result, 200);
    }

    function testDiv() public pure {
        uint256 a = 20;
        uint256 b = 10;
        uint256 result = Safe112.div(uint112(a), uint112(b));
        console.log("Div result:", result);
        assertEq(result, 2);
    }

    function testMod() public pure {
        uint256 a = 20;
        uint256 b = 7;
        uint256 result = Safe112.mod(uint112(a), uint112(b));
        console.log("Mod result:", result);
        assertEq(result, 6);
    }
}
