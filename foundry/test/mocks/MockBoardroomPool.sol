// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IRewardPool} from "src/interfaces/IRewardPool.sol";

contract MockBoardroomPool is IRewardPool {
    using SafeERC20 for IERC20;
    using Math for uint256;

    address public token;
    uint256 public tokenPerCall;
    bool public no;

    constructor(address _token, uint256 amount, uint256 slice, bool no_) {
        token = _token;
        tokenPerCall = amount / slice;
        no = no_;
    }

    function collect() external override returns (address, uint256) {
        require(!no, "MockBoardroomPool: no");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) {
            return (token, balance);
        }

        uint256 amount = Math.min(balance, tokenPerCall);
        IERC20(token).safeTransfer(msg.sender, amount);
        return (token, amount);
    }
}
