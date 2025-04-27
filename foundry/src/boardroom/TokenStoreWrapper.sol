// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITokenStore} from "../interfaces/ITokenStore.sol";

abstract contract TokenStoreWrapper is Context {
    using SafeERC20 for IERC20;

    IERC20 public share;
    ITokenStore public store;

    function deposit(uint256 amount) public virtual {
        share.safeTransferFrom(_msgSender(), address(this), amount);
        share.safeIncreaseAllowance(address(store), amount);
        store.deposit(_msgSender(), amount);
    }

    function withdraw(uint256 amount) public virtual {
        store.withdraw(_msgSender(), amount);
        share.safeTransfer(_msgSender(), amount);
    }
}
