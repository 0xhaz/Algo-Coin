// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IPoolStore} from "../interfaces/IPoolStore.sol";

abstract contract PoolStoreWrapper is Context {
    using SafeERC20 for IERC20;

    IPoolStore public store;

    function deposit(uint256 _pid, uint256 _amount) public virtual {
        IERC20(store.tokenOf(_pid)).safeTransferFrom(_msgSender(), address(this), _amount);

        store.deposit(_pid, _msgSender(), _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public virtual {
        store.withdraw(_pid, _msgSender(), _amount);

        IERC20(store.tokenOf(_pid)).safeTransfer(_msgSender(), _amount);
    }
}
