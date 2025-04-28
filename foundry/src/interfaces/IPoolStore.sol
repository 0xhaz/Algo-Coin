// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IPoolStore {
    /*//////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    error PoolStore__CallerIsNotOwner();
    error PoolStore__InvalidPoolId();
    error PoolStore__NotInEmergency();
    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed operator, address indexed owner, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed operator, address owner, uint256 indexed pid, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                  CALLS
    //////////////////////////////////////////////////////////////*/

    function totalWeight() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function poolIdsOf(address _token) external view returns (uint256[] memory);

    function nameOf(uint256 _pid) external view returns (string memory);

    function tokenOf(uint256 _pid) external view returns (address);

    function weightOf(uint256 _pid) external view returns (uint256);

    function totalSupply(uint256 _pid) external view returns (uint256);

    function balanceOf(uint256 _pid, address _owner) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            TRANSACTIONS
    //////////////////////////////////////////////////////////////*/
    function deposit(uint256 _pid, address _owner, uint256 _amount) external;

    function withdraw(uint256 _pid, address _owner, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}
