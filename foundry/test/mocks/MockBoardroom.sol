// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Operator} from "src/access/Operator.sol";
import {IBoardroomV2} from "src/interfaces/IBoardroomV2.sol";

contract MockBoardroom is IBoardroomV2, Operator {
    using SafeERC20 for IERC20;

    function totalSupply() external pure override returns (uint256) {
        return 0;
    }

    function balanceOf(address _owner) external pure override returns (uint256) {
        return uint256(uint160(_owner));
    }

    function rewardTokenAt(uint256 _index) external pure override returns (address) {
        return address(uint160(_index));
    }

    function rewardTokensLength() external pure override returns (uint256) {
        return 0;
    }

    function rewardPoolsAt(uint256 _index) external pure override returns (address) {
        return address(uint160(_index));
    }

    function rewardPoolsLength() external pure override returns (uint256) {
        return 0;
    }

    function lastSnapshotIndex(address _token) external pure override returns (uint256) {
        require(_token == address(0x0), "Mock");
        return 0;
    }

    function rewardEarned(address _token, address _director) external pure override returns (uint256) {
        require(_token == address(0x0), "Mock");
        require(_director == address(0x0), "Mock");
        return 0;
    }

    function deposit(uint256 _amount) external override {}

    function withdraw(uint256 _amount) external override {}

    function claimReward() external override {}

    function exit() external override {}

    function collectReward() external override {
        emit RewardCollected(msg.sender, msg.sender, msg.sender, 0);
    }
}
