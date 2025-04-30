// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPool} from "../interfaces/IPool.sol";
import {Operator} from "../access/Operator.sol";

contract PoolProxy is Operator, ERC20 {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address private pool;
    uint256 private pid;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20("Pool Proxy Token", "PPT") {}

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

    /*//////////////////////////////////////////////////////////////
                          OPERATOR FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function collect() external onlyOperator returns (address, uint256) {
        IPool(pool).claimReward(pid);

        address token = IPool(pool).tokenOf(pid);
        uint256 amount = IERC20(token).balanceOf(address(this));

        IERC20(token).safeTransfer(_msgSender(), amount);

        return (token, amount);
    }
}
