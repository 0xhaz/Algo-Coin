// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {FixedPoint} from "src/libraries/FixedPoint.sol";
import {UniswapV2Library} from "src/libraries/UniswapV2Library.sol";
import {IUniswapV2Pair} from "src/interfaces/IUniswapV2Pair.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uin32, i.e [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using conterfactuals to save gas and avoid a call to sync
    function currentCumulativePrices(address pair)
        internal
        view
        returns (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp)
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();

        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactuals
            price0Cumulative += FixedPoint.fraction(reserve1, reserve0)._x * timeElapsed;
            // counterfactuals
            price1Cumulative += FixedPoint.fraction(reserve0, reserve1)._x * timeElapsed;
        }
    }
}
