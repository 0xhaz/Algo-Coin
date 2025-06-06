// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IRewardPool {
    function collect() external returns (address, uint256);
}
