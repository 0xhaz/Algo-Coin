// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Distribution} from "./Distribution.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IPoolStore} from "../interfaces/IPoolStore.sol";
import {Operator} from "../access/Operator.sol";
import {ISharedRewardPool} from "../interfaces/ISharedRewardPool.sol";

contract PickleProxy is Operator, ERC20, ISharedRewardPool {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address private pool;
    uint256 private pid;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20("Vault Proxy Token", "VPT") {}

    /*//////////////////////////////////////////////////////////////
                                GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    function setPool(address _newPool) public onlyOwner {
        pool = _newPool;
    }

    function setPid(uint256 _newPid) public onlyOwner {
        pid = _newPid;
    }

    function deposit(uint256 _amount) public onlyOwner {
        _mint(address(this), _amount);
        approve(pool, _amount);
        IPool(pool).deposit(pid, _amount);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        IPool(pool).withdraw(pid, _amount);
        _burn(address(this), _amount);
    }

    function deposit(uint256, uint256 _amount) external override onlyOperator {
        IERC20 token = IERC20(IPool(pool).tokenOf(pid));
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256, uint256 _amount) external override onlyOperator {
        IERC20 token = IERC20(IPool(pool).tokenOf(pid));
        token.safeTransfer(msg.sender, _amount);
    }

    function pendingShare(uint256, address) external view override returns (uint256) {
        return IPool(pool).rewardEarned(pid, address(this));
    }

    function userInfo(uint256, address) external view override returns (uint256, uint256) {
        return (IPool(pool).balanceOf(pid, address(this)), uint256(0));
    }

    function emergencyWithdraw(uint256) external override onlyOperator {
        IPoolStore(Distribution(pool).store()).emergencyWithdraw(pid);
        IERC20 token = IERC20(IPool(pool).tokenOf(pid));
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
}
