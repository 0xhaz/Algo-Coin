// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Operator} from "../access/Operator.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBoardroomV2} from "../interfaces/IBoardroomV2.sol";
import {IBoardroomV2Gov} from "../interfaces/IBoardroomV2Gov.sol";
import {IRewardPool} from "../interfaces/IRewardPool.sol";
import {TokenStoreWrapper, ITokenStore} from "./TokenStoreWrapper.sol";

/**
 * @title Boardroom
 * @author 0xhaz
 * @notice This contract handles dividend claims from Share holders
 */
contract BoardroomV2 is IBoardroomV2, IBoardroomV2Gov, TokenStoreWrapper, Ownable {
    /*//////////////////////////////////////////////////////////////
                                  TYPES
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                            STRUCTURES
    //////////////////////////////////////////////////////////////*/
    struct Boardseat {
        uint256 lastSnapshotIndex; // block timestamp of last (deposit / withdrawal / dividend claim) of an account
        uint256 rewardEarned; // the account's current number of shares staked
    }

    struct BoardSnapshot {
        uint256 at; // block timestamp when new seigniorage was added
        uint256 rewardReceived; // the amount of BC seigniorage that was newly added
        uint256 rewardPerShare; // total number of staked shares at the time of seigniorage generation
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    bool public migrated;

    uint256 constant PRECISION = 1e18;

    EnumerableSet.AddressSet private s_rewardTokens;
    EnumerableSet.AddressSet private s_rewardPools;

    BoardSnapshot genesis = BoardSnapshot({at: block.number, rewardReceived: 0, rewardPerShare: 0});

    /// @dev Records the history of past seigniorage events.
    /// @dev This array is used to calculate the amount of dividends that a specific share holders has accrued
    mapping(address => BoardSnapshot[]) private s_history;

    /// @dev Records the current state of BS stakers
    mapping(address => mapping(address => Boardseat)) public s_seats;

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier checkMigration() {
        if (!migrated) revert Boardroom__NotMigrated();
        _;
    }

    /// @notice Checks whether sender has shares staked
    modifier directorExists() {
        if (store.balanceOf(_msgSender()) == 0) revert Boardroom__AbsentDirector();
        _;
    }

    modifier updateReward(address _director) {
        collectReward();

        for (uint256 i; i < s_rewardTokens.length(); ++i) {
            address token = s_rewardTokens.at(i);

            if (_director != address(0x0)) {
                Boardseat memory seat = s_seats[token][_director];
                seat.rewardEarned = rewardEarned(token, _director);
                seat.lastSnapshotIndex = lastSnapshotIndex(token);
                s_seats[token][_director] = seat;
            }
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _cash, address _share, address _store) Ownable(_msgSender()) {
        share = IERC20(_share);
        store = ITokenStore(_store);

        addRewardToken(_cash);
        addRewardToken(_share);
    }

    /*//////////////////////////////////////////////////////////////
                            GOV - OWNER ONLY
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev blocks deposit function
     */
    function migrate() external override onlyOwner {
        migrated = true;
    }

    /**
     * @param _token reward token address
     */
    function addRewardToken(address _token) public override onlyOwner {
        s_rewardTokens.add(_token);
        s_history[_token].push(genesis);

        emit RewardTokenAdded(_msgSender(), _token);
    }

    /**
     * @param _token reward token address
     */
    function removeRewardToken(address _token) public override onlyOwner {
        s_rewardTokens.remove(_token);

        emit RewardTokenRemoved(_msgSender(), _token);
    }

    /**
     * @param _token reward token address
     */
    function addRewardPool(address _token) public override onlyOwner {
        s_rewardPools.add(_token);

        emit RewardPoolAdded(_msgSender(), _token);
    }

    /**
     * @param _token reward token address
     */
    function removeRewardPool(address _token) public override onlyOwner {
        s_rewardPools.remove(_token);

        emit RewardPoolRemoved(_msgSender(), _token);
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/
    /**
     * @return total staked amount
     */
    function totalSupply() external view override returns (uint256) {
        return store.totalSupply();
    }

    /**
     *
     * @param _owner staker address
     * @return staked amount
     */
    function balanceOf(address _owner) external view override returns (uint256) {
        return store.balanceOf(_owner);
    }

    /**
     * @param _index index of reward token
     * @return reward token address
     */
    function rewardTokenAt(uint256 _index) external view override returns (address) {
        return s_rewardTokens.at(_index);
    }

    /**
     * @return number of reward tokens
     */
    function rewardTokensLength() external view override returns (uint256) {
        return s_rewardTokens.length();
    }

    /**
     * @param index index of reward pool
     * @return reward pool address
     */
    function rewardPoolsAt(uint256 index) external view override returns (address) {
        return s_rewardPools.at(index);
    }

    /**
     * @return number of reward pools
     */
    function rewardPoolsLength() external view override returns (uint256) {
        return s_rewardPools.length();
    }

    /*/////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @param token reward token address
     * @return last snapshot index
     */
    function lastSnapshotIndex(address token) public view override returns (uint256) {
        return s_history[token].length - 1;
    }

    /**
     *
     * @param token reward token address
     * @param director staker address
     * @return reward earned
     */
    function rewardEarned(address token, address director) public view override returns (uint256) {
        uint256 latestRPS = getLastSnapshot(token).rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(token, director).rewardPerShare;

        return (store.balanceOf(director) * (latestRPS - storedRPS)) / PRECISION + s_seats[token][director].rewardEarned;
    }

    /*/////////////////////////////////////////////////////////////
                            TRANSACTIONS 
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev deposit tokens to boardroom
     * @param amount deposit amount
     */
    function deposit(uint256 amount)
        public
        override(IBoardroomV2, TokenStoreWrapper)
        checkMigration
        updateReward(_msgSender())
    {
        super.deposit(amount);

        emit DepositShare(_msgSender(), amount);
    }

    /**
     * @dev withdraw tokens from boardroom
     * @param amount amount of staked tokens
     */
    function withdraw(uint256 amount)
        public
        override(IBoardroomV2, TokenStoreWrapper)
        directorExists
        updateReward(_msgSender())
    {
        super.withdraw(amount);

        emit WithdrawShare(_msgSender(), amount);
    }

    /**
     * @dev claim reward tokens
     */
    function claimReward() public override updateReward(_msgSender()) {
        for (uint256 i; i < s_rewardTokens.length(); ) {
            address token = s_rewardTokens.at(i);
            uint256 reward = s_seats[token][_msgSender()].rewardEarned;
            unchecked {
                ++i;
            }
            if (reward > 0) {
                s_seats[token][_msgSender()].rewardEarned = 0;
                IERC20(token).safeTransfer(_msgSender(), reward);

                emit RewardClaimed(_msgSender(), token, reward);
            }
        }
    }

    /**
     * @dev withdraw and claim rewards
     */
    function exit() external override {
        uint256 balance = store.balanceOf(_msgSender());
        withdraw(balance);
        claimReward();
    }

    /**
     * @dev collect reward tokens from reward pools
     */
    function collectReward() public override {
        uint256 totalSupply_ = store.totalSupply();

        if (totalSupply_ > 0) {
            for (uint256 i; i < s_rewardPools.length(); ++i) {
                try IRewardPool(s_rewardPools.at(i)).collect() returns (address token, uint256 amount) {
                    if (amount == 0) {
                        continue;
                    }

                    uint256 prevRPS = getLastSnapshot(token).rewardPerShare;
                    uint256 nextRPS = prevRPS + (amount * PRECISION) / totalSupply_;

                    BoardSnapshot memory newSnapshot =
                        BoardSnapshot({at: block.number, rewardReceived: amount, rewardPerShare: nextRPS});
                    s_history[token].push(newSnapshot);

                    emit RewardCollected(_msgSender(), s_rewardPools.at(i), token, amount);
                } catch Error(string memory reason) {
                    emit RewardCollectionFailedWithReason(_msgSender(), s_rewardPools.at(i), reason);
                }
            }
        }
    }

    /**
     * @param _token reward token address
     * @return last snapshot of token history
     */
    function getLastSnapshot(address _token) internal view returns (BoardSnapshot memory) {
        return s_history[_token][lastSnapshotIndex(_token)];
    }

    /**
     * @param _token reward token address
     * @param _director staker address
     * @return last snapshot of token history
     */
    function getLastSnapshotOf(address _token, address _director) internal view returns (BoardSnapshot memory) {
        return s_history[_token][s_seats[_token][_director].lastSnapshotIndex];
    }
}
