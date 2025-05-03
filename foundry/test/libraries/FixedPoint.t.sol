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

    function testDiv() public pure {
        uint256 value = 1e18;
        FixedPoint.uq112x112 memory encodedValue = FixedPoint.encode(uint112(value));
        console.log("Encoded value:", encodedValue._x);

        uint256 divisor = 2e18;
        FixedPoint.uq112x112 memory dividedValue = FixedPoint.div(encodedValue, uint112(divisor));
        console.log("Divided value:", dividedValue._x);

        assertEq(dividedValue._x, (value << RESOLUTION) / divisor);

        uint256 expectedValue = ((value * Q112) / divisor) >> RESOLUTION;
        uint112 decodedValue = FixedPoint.decode(dividedValue);
        console.log("Decoded value:", decodedValue);
        assertEq(decodedValue, expectedValue);
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

    function testFraction() public pure {
        uint256 numerator = 1e18;
        uint256 denominator = 2e18;
        FixedPoint.uq112x112 memory fractionValue = FixedPoint.fraction(uint112(numerator), uint112(denominator));
        console.log("Fraction value:", fractionValue._x);
        assertEq(fractionValue._x, (uint224(numerator) << RESOLUTION) / denominator);

        uint256 readableValue = (fractionValue._x * 1e18) >> RESOLUTION;
        console.log("Readable value:", readableValue);
        assertEq(readableValue, numerator * 1e18 / denominator);
    }

    function testReciprocal() public pure {
        uint256 value = 1e18;
        FixedPoint.uq112x112 memory encodedValue = FixedPoint.encode(uint112(value));
        console.log("Encoded value:", encodedValue._x);

        FixedPoint.uq112x112 memory reciprocalValue = FixedPoint.reciprocal(encodedValue);
        console.log("Reciprocal value:", reciprocalValue._x);
        assertEq(reciprocalValue._x, Q224 / (value << RESOLUTION));

        uint256 readableValue = (reciprocalValue._x * 1e36) >> RESOLUTION;
        console.log("Readable value with 18 decimals:", readableValue);
        uint256 expectedValue = (1e36) / value;
        assertApproxEqAbs(readableValue, expectedValue, 1e12);
    }

    function testSqrt() public pure {
        uint256 value = 1e18;
        FixedPoint.uq112x112 memory encodedValue = FixedPoint.encode(uint112(value));
        console.log("Encoded value:", encodedValue._x);

        FixedPoint.uq112x112 memory sqrtValue = FixedPoint.sqrt(encodedValue);
        console.log("Square root value:", sqrtValue._x);
        assertEq(sqrtValue._x, FixedPoint.sqrt(FixedPoint.uq112x112(uint224(value << RESOLUTION)))._x);

        uint256 readableValue = (sqrtValue._x * 1e18) >> RESOLUTION;
        console.log("Readable value:", readableValue);
        uint256 expectedValue = FixedPoint.decode(FixedPoint.sqrt(FixedPoint.encode(uint112(value))));
        assertApproxEqAbs(readableValue, expectedValue, 1e36);
    }
}
