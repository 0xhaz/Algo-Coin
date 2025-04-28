// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolStoreGov {
    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event EmergencyReported(address indexed reporter);

    event EmergencyResolved(address indexed resolver);

    event WeightFeederChanged(address indexed operator, address indexed oldFeeder, address indexed newFeeder);

    event PoolAdded(address indexed operator, uint256 indexed pid, string name, address token, uint256 weight);

    event PoolWeightChanged(address indexed operator, uint256 indexed pid, uint256 from, uint256 to);

    event PoolNameChanged(address indexed operator, uint256 indexed pid, string from, string to);

    /*//////////////////////////////////////////////////////////////
                                TRANSACTIONS
    //////////////////////////////////////////////////////////////*/
    function reportEmergency() external;

    function resolveEmergency() external;

    function setWeightFeeder(address _newFeeder) external;

    function addPool(string memory _name, IERC20 _token, uint256 _weight) external;

    function setPool(uint256 _pid, uint256 _weight) external;

    function setPoolName(uint256 _pid, string memory _name) external;
}
