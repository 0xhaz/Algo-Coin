// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IBoardroomV2Gov {
    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event RewardTokenAdded(address indexed operator, address token);
    event RewardTokenRemoved(address indexed operator, address token);
    event RewardPoolAdded(address indexed operator, address pool);
    event RewardPoolRemoved(address indexed operator, address pool);

    /*//////////////////////////////////////////////////////////////
                                TRANSACTIONS
    //////////////////////////////////////////////////////////////*/
    function migrate() external;

    function addRewardToken(address _token) external;

    function removeRewardToken(address _token) external;

    function addRewardPool(address _pool) external;

    function removeRewardPool(address _pool) external;
}
