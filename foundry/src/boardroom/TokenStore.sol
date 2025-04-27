// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITokenStore} from "../interfaces/ITokenStore.sol";
import {ITokenStoreGov} from "../interfaces/ITokenStoreGov.sol";
import {Operator} from "../access/Operator.sol";

contract TokenStore is ITokenStore, ITokenStoreGov, Operator {
    /*//////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    error TokenStore__NotInEmergency();
    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address public override token;

    uint256 private s_totalSupply;

    mapping(address => uint256) private s_balances;

    bool private emergency = false;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address token_) {
        token = token_;
    }

    /*//////////////////////////////////////////////////////////////
                            GOV - OWNER ONLY
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev CAUTION: DO NOT USE IN NORMAL SITUATION
     * @notice Enable emergency withdraw
     */
    function reportEmergency() public override onlyOwner {
        emergency = true;
        emit EmergencyReported(_msgSender());
    }

    /**
     * @dev CAUTION: DO NOT USE IN NORMAL SITUATION
     * @notice Disable emergency withdraw
     */
    function resolveEmergency() external override {
        emergency = false;
        emit EmergencyResolved(_msgSender());
    }

    /**
     * @dev CAUTION: MUST USE 1:1 TOKEN MIGRATION
     */
    function setToken(address newToken) public override onlyOwner {
        address oldToken = token;
        token = newToken;
        IERC20(newToken).safeTransferFrom(msg.sender, address(this), totalSupply());

        emit TokenChanged(_msgSender(), newToken, oldToken);
    }

    function getEmergencyStatus() public view onlyOwner returns (bool) {
        return emergency;
    }

    /*//////////////////////////////////////////////////////////////
                            CALLS - ANYONE
    //////////////////////////////////////////////////////////////*/
    /**
     * @return total staked token amount
     */
    function totalSupply() public view override returns (uint256) {
        return s_totalSupply;
    }

    /**
     * @param _owner staker address
     * @return staked token amount
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        return s_balances[_owner];
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSACTIONS - OPERATOR ONLY
    //////////////////////////////////////////////////////////////*/
    /**
     * @param _owner staker address
     * @param _amount staked token amount
     */
    function deposit(address _owner, uint256 _amount) public override onlyOperator {
        s_totalSupply = s_totalSupply + _amount;
        s_balances[_owner] = s_balances[_owner] + _amount;
        IERC20(token).safeTransferFrom(_msgSender(), address(this), _amount);

        emit Deposit(_msgSender(), _owner, _amount);
    }

    /**
     * @param _owner staker address
     * @param _amount staked token amount
     */
    function withdraw(address _owner, uint256 _amount) public override onlyOperator {
        s_totalSupply = s_totalSupply - _amount;
        s_balances[_owner] = s_balances[_owner] - _amount;
        IERC20(token).safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), _owner, _amount);
    }

    /**
     * @notice Anyone can withdraw its balance even if is not the operator
     */
    function emergencyWithdraw() public override {
        if (!emergency) revert TokenStore__NotInEmergency();

        uint256 balance = s_balances[_msgSender()];
        s_balances[_msgSender()] = 0;
        IERC20(token).safeTransfer(_msgSender(), balance);

        emit Withdraw(_msgSender(), _msgSender(), balance);
    }
}
