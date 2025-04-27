// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface ITokenStore {
    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed operator, address indexed owner, uint256 amount);
    event Withdraw(address indexed operator, address indexed owner, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                  CALLS
    //////////////////////////////////////////////////////////////*/
    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                             TRANSACTIONS
    //////////////////////////////////////////////////////////////*/
    function deposit(address _owner, uint256 _amount) external;

    function withdraw(address _owner, uint256 _amount) external;

    function emergencyWithdraw() external;
}
