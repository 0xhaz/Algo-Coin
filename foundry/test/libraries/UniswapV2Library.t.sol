// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Library} from "src/libraries/UniswapV2Library.sol";
import {IUniswapV2Pair} from "src/interfaces/IUniswapV2Pair.sol";

contract UniswapV2LibraryTest is Test {
    address tokenA = address(0x1);
    address tokenB = address(0x2);
    address factory = address(0x3);

    function testSortTokens() public view {
        (address token0, address token1) = UniswapV2Library.sortTokens(tokenA, tokenB);
        assertEq(token0, tokenA);
        assertEq(token1, tokenB);

        (token0, token1) = UniswapV2Library.sortTokens(tokenB, tokenA);
        assertEq(token0, tokenA);
        assertEq(token1, tokenB);
    }

    function testQuote() public pure {
        uint256 amountA = 1000;
        uint256 reserveA = 2000;
        uint256 reserveB = 3000;

        uint256 expectedAmountB = (amountA * reserveB) / reserveA;
        uint256 amountB = UniswapV2Library.quote(amountA, reserveA, reserveB);
        assertEq(amountB, expectedAmountB);
    }

    function testGetAmountOut() public pure {
        uint256 amountIn = 1000;
        uint256 reserveIn = 5000;
        uint256 reserveOut = 10000;

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        uint256 expectedAmountOut = numerator / denominator;

        uint256 amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
        assertEq(amountOut, expectedAmountOut);
    }

    function testGetAmountIn() public pure {
        uint256 amountOut = 1000;
        uint256 reserveIn = 5000;
        uint256 reserveOut = 10000;

        uint256 numerator = (reserveIn * amountOut) * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        uint256 expectedAmountIn = (numerator / denominator) + 1;
        // Adding 1 to ensure rounding up

        uint256 amountIn = UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
        assertEq(amountIn, expectedAmountIn);
    }

    function testPairFor() public view {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        address expectedPair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
        assertEq(pair, expectedPair);
    }

    function testGetReserves() public {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint256 reserveA = 1000;
        uint256 reserveB = 2000;
        uint32 blockTimestampLast = 1234567890;

        vm.mockCall(pair, abi.encodeWithSignature("getReserves()"), abi.encode(reserveA, reserveB, blockTimestampLast));

        (uint256 rA, uint256 rB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        assertEq(rA, reserveA);
        assertEq(rB, reserveB);
    }

    function testAmountsOut() public {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        uint256 amountIn = 1000;
        uint256 reserveA = 2000;
        uint256 reserveB = 3000;

        vm.mockCall(
            UniswapV2Library.pairFor(factory, tokenA, tokenB),
            abi.encodeWithSignature("getReserves()"),
            abi.encode(reserveA, reserveB, 1234567890)
        );

        uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveB;
        uint256 denominator = (reserveA * 1000) + amountInWithFee;
        uint256 expectedAmountOut = numerator / denominator;

        assertEq(amounts[0], amountIn);
        assertEq(amounts[1], expectedAmountOut);
        assertEq(amounts.length, 2);
        assertEq(path[0], tokenA);
        assertEq(path[1], tokenB);
    }

    function testAmountsIn() public {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        uint256 amountOut = 1000;
        uint256 reserveA = 2000;
        uint256 reserveB = 3000;

        vm.mockCall(
            UniswapV2Library.pairFor(factory, tokenA, tokenB),
            abi.encodeWithSignature("getReserves()"),
            abi.encode(reserveA, reserveB, 1234567890)
        );

        uint256[] memory amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);

        uint256 numerator = (reserveA * amountOut) * 1000;
        uint256 denominator = (reserveB - amountOut) * 997;
        uint256 expectedAmountIn = (numerator / denominator) + 1; // Adding 1 to ensure rounding up

        assertEq(amounts[0], expectedAmountIn);
        assertEq(amounts[1], amountOut);
        assertEq(amounts.length, 2);
        assertEq(path[0], tokenA);
        assertEq(path[1], tokenB);
    }
}
