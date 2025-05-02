// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {FixedPoint} from "src/libraries/FixedPoint.sol";

contract FixedPointTest is Test {
    using FixedPoint for uint256;

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    function testEncodeDecode() public pure {
        uint256 value = 1e18;
        FixedPoint.uq112x112 memory encodedValue = FixedPoint.encode(uint112(value));
        console.log("Encoded value:", encodedValue._x);
        assertEq(encodedValue._x, value << RESOLUTION);

        uint112 decodedValue = FixedPoint.decode(FixedPoint.uq112x112(encodedValue._x));
        console.log("Decoded value:", decodedValue);
        assertEq(decodedValue, value);
    }

    function testEncodeDecode144() public pure {
        uint256 value = 1e18;

        FixedPoint.uq144x112 memory encodedValue = FixedPoint.encode144(uint144(value));
        console.log("Encoded value:", encodedValue._x);
        assertEq(encodedValue._x, value << RESOLUTION);

        uint144 decodedValue = FixedPoint.decode144(FixedPoint.uq144x112(encodedValue._x));
        console.log("Decoded value:", decodedValue);
        assertEq(decodedValue, value);
    }

    function testMul() public pure {
        uint256 value = 1e18;
        FixedPoint.uq112x112 memory encodedValue = FixedPoint.encode(uint112(value));
        console.log("Encoded value:", encodedValue._x);

        uint256 multiplier = 2e18;
        FixedPoint.uq144x112 memory multipliedValue = FixedPoint.mul(encodedValue, multiplier);

        console.log("Multiplied value:", multipliedValue._x);
        assertEq(multipliedValue._x, (value << RESOLUTION) * multiplier);

        uint256 expectedValue = (value * multiplier);
        uint144 decodedValue = FixedPoint.decode144(multipliedValue);
        console.log("Decoded value:", decodedValue);
        assertEq(decodedValue, expectedValue);
    }
}
