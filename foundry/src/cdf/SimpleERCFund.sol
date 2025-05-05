// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Operator} from "src/access/Operator.sol";
import {ISimpleERCFund} from "src/interfaces/ISimpleERCFund.sol";

contract SimpleERCFund is ISimpleERCFund, Operator {
    using SafeERC20 for IERC20;

    function deposit(address token, uint256 amount, string memory reason) public override {
        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        emit Deposit(_msgSender(), block.timestamp, reason);
    }

    function withdraw(address token, uint256 amount, address to, string memory reason) public override onlyOperator {
        IERC20(token).safeTransfer(to, amount);
        emit Withdrawal(_msgSender(), to, block.timestamp, reason);
    }
}
