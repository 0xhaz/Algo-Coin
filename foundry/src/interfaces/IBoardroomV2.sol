// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface IBoardroomV2 {
    /*//////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    error Boardroom__NotMigrated();
    error Boardroom__AbsentDirector();

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when shares are staked
    event DepositShare(address indexed owner, uint256 amount);

    /// @notice Emitted when shares are withdrawn
    event WithdrawShare(address indexed owner, uint256 amount);

    /// @notice Emitted when Share dividends are paid
    event RewardClaimed(address indexed owner, address indexed token, uint256 amount);

    /// @notice Emitted when a reward token is collected
    event RewardCollected(address indexed operator, address indexed target, address indexed token, uint256 amount);

    /// @notice Emitted when a reward claimed failed with a revert string
    event RewardCollectionFailedWithReason(address indexed operator, address indexed target, string reason);

    /// @notice Emitted when a reward claimed failed with a revert data
    event RewardCollectionFailedWithData(address indexed operator, address indexed target, bytes data);

    /*//////////////////////////////////////////////////////////////
                                CALLS
    //////////////////////////////////////////////////////////////*/
    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function rewardTokenAt(uint256 index) external view returns (address);

    function rewardTokensLength() external view returns (uint256);

    function rewardPoolsAt(uint256 index) external view returns (address);

    function rewardPoolsLength() external view returns (uint256);

    function lastSnapshotIndex(address token) external view returns (uint256);

    function rewardEarned(address token, address director) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                               TRANSACTIONS
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function claimReward() external;

    function exit() external;

    function collectReward() external;
}
