// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Operator} from "../access/Operator.sol";
import {IPool, IPoolGov} from "../interfaces/IPool.sol";
import {PoolStoreWrapper, IPoolStore} from "./PoolStoreWrapper.sol";

contract Distribution is IPool, IPoolGov, PoolStoreWrapper, Operator {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address private share;

    bool private stopped;
    uint256 private rewardRate;
    uint256 private rewardRateExtra;

    uint256 private rewardRateBeforeHalve;

    uint256 private period;
    uint256 private periodFinish;
    uint256 private startTime;

    uint256 private constant HALVE_REWARD_RATE = 75e18;
    uint256 private constant MAX_REWARD_RATE = 100e18;
    uint256 private constant PRECISION = 1e18;

    mapping(address => bool) private approvals;
    mapping(uint256 => Pool) private pools;
    mapping(uint256 => mapping(address => User)) private users;

    /*//////////////////////////////////////////////////////////////
                                 STRUCTURES
    //////////////////////////////////////////////////////////////*/

    struct User {
        uint256 amount;
        uint256 reward;
        uint256 rewardPerTokenPaid;
    }

    struct Pool {
        bool initialized;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    /*//////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /**
     * @param _pid pool id
     * @param _target update target. If it's empty, skip the update
     */
    modifier updateReward(uint256 _pid, address _target) {
        _updatePool(_pid);

        if (_target != address(0)) {
            _updateUser(_pid, _target);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _share, address _poolStore) {
        share = _share;
        store = IPoolStore(_poolStore);
    }

    /*//////////////////////////////////////////////////////////////
                                 GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Set the period to distribute rewards
     * @param _startTime starting time to distribute rewards
     * @param _period distribution period
     */
    function setPeriod(uint256 _startTime, uint256 _period) public override onlyOperator {
        if (startTime <= block.timestamp && block.timestamp < periodFinish) {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = leftover / _period;
        }

        period = _period;
        startTime = _startTime;
        periodFinish = _startTime + _period;
    }

    /**
     * @dev Notify the contract with the amount of rewards to distribute
     * @param _amount amount of rewards to distribute
     */
    function setReward(uint256 _amount) public override onlyOperator {
        if (block.timestamp > periodFinish) revert IPool__AlreadyFinished();

        if (startTime <= block.timestamp) {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (_amount + leftover) / (periodFinish - block.timestamp);
        } else {
            rewardRate = (rewardRate + _amount) / (periodFinish - startTime);
        }
    }

    /**
     * @dev Notify the contract with the amount of extra rewards to distribute
     * @param _extra amount of extra rewards to distribute
     */
    function setExtraRewardRate(uint256 _extra) public override onlyOwner {
        rewardRateExtra = _extra;
    }

    /**
     * @dev STOP DISTRIBUTION
     */
    function stop() public override onlyOwner {
        periodFinish = block.timestamp;
        stopped = true;
    }

    /**
     * @dev must update all pool reward before migration
     * @param _newPool new pool address to migrate
     * @param _amount the amount of rewards to migrate
     */
    function migrate(address _newPool, uint256 _amount) public override onlyOwner {
        if (!stopped) revert IPool__NotStopped();
        IERC20(share).safeTransfer(_newPool, _amount);

        uint256 remaining = startTime + period - periodFinish;
        uint256 leftover = remaining * rewardRate;

        IPoolGov(_newPool).setPeriod(block.timestamp + 1, remaining);
        IPoolGov(_newPool).setReward(leftover);
    }

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _pid pool id
     * @return token address of the pool
     */
    function tokenOf(uint256 _pid) external view override returns (address) {
        return store.tokenOf(_pid);
    }

    /**
     * @param _token pool token address
     * @return pool ids of the token
     */
    function poolIdsOf(address _token) external view override returns (uint256[] memory) {
        return store.poolIdsOf(_token);
    }

    /**
     * @param _pid pool id
     * @return total supply of the pool
     */
    function totalSupply(uint256 _pid) external view override returns (uint256) {
        return store.totalSupply(_pid);
    }

    /**
     *
     * @param _pid pool id
     * @param _owner staker address
     * @return balance of the staker
     */
    function balanceOf(uint256 _pid, address _owner) external view override returns (uint256) {
        return store.balanceOf(_pid, _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             PUBLIC VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     *
     * @param _pid pool id
     * @return reward rate of the pool
     */
    function rewardRatePerPool(uint256 _pid) public view override returns (uint256) {
        return _rewardRatePerPool(_pid, rewardRate + rewardRateExtra);
    }

    /**
     * @return applicable reward time
     */
    function applicableRewardTime() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken(uint256 _pid) public view override returns (uint256) {
        Pool memory pool = pools[_pid];
        uint256 supply = store.totalSupply(_pid);

        if (supply == 0 || block.timestamp < startTime) {
            return pool.rewardPerTokenStored;
        }

        if (pool.rewardRate != 0 && pool.rewardRate == rewardRateBeforeHalve) {
            uint256 beforeHalve =
                (startTime - pool.lastUpdateTime) * _rewardRatePerPool(_pid, rewardRateBeforeHalve) * PRECISION / supply;
            uint256 afterHalve = (applicableRewardTime() - startTime) * (rewardRatePerPool(_pid) * PRECISION) / supply;

            return pool.rewardPerTokenStored + beforeHalve + afterHalve;
        } else {
            return pool.rewardPerTokenStored
                + (applicableRewardTime() - pool.lastUpdateTime) * (rewardRatePerPool(_pid) * PRECISION) / supply;
        }
    }

    /**
     *
     * @param _pid pool id
     * @param _target target address
     * @return reward earned per pool
     */
    function rewardEarned(uint256 _pid, address _target) public view override returns (uint256) {
        User memory user = users[_pid][_target];
        uint256 balanceOfUser = store.balanceOf(_pid, _target);

        return balanceOfUser * (rewardPerToken(_pid) - user.rewardPerTokenPaid) / PRECISION + user.reward;
    }

    /*//////////////////////////////////////////////////////////////
                             PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _pids array of pool ids
     */
    function massUpdate(uint256[] memory _pids) public override {
        for (uint256 i; i < _pids.length;) {
            update(_pids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @param _pid pool id
     */
    function update(uint256 _pid) public override updateReward(_pid, address(0x0)) {}

    /**
     * @param _pid pool id
     * @param _amount  amount to deposit
     */
    function deposit(uint256 _pid, uint256 _amount)
        public
        override(IPool, PoolStoreWrapper)
        updateReward(_pid, _msgSender())
    {
        if (stopped) revert IPool__Stopped();

        super.deposit(_pid, _amount);

        emit DepositToken(_msgSender(), _pid, _amount);
    }

    /**
     *
     * @param _pid pool id
     * @param _amount  amount to withdraw
     */
    function withdraw(uint256 _pid, uint256 _amount)
        public
        override(IPool, PoolStoreWrapper)
        updateReward(_pid, _msgSender())
    {
        if (stopped) revert IPool__Stopped();

        super.withdraw(_pid, _amount);

        emit WithdrawToken(_msgSender(), _pid, _amount);
    }

    /**
     * @param _pid pool id
     */
    function claimReward(uint256 _pid) public override updateReward(_pid, _msgSender()) {
        uint256 reward = users[_pid][_msgSender()].reward;

        if (reward > 0) {
            users[_pid][_msgSender()].reward = 0;
            IERC20(share).safeTransfer(_msgSender(), reward);

            emit RewardClaimed(_msgSender(), _pid, reward);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _pid pool id
     * @notice exit from the pool
     */
    function exit(uint256 _pid) external override {
        uint256 balanceOfUser = store.balanceOf(_pid, _msgSender());
        withdraw(_pid, balanceOfUser);
        claimReward(_pid);
    }

    function getHalvingRewardRate() external pure returns (uint256) {
        return HALVE_REWARD_RATE;
    }

    function getRewardRateBeforeHalve() external view returns (uint256) {
        return rewardRateBeforeHalve;
    }

    function getMaxRewardRate() external pure returns (uint256) {
        return MAX_REWARD_RATE;
    }

    function getShare() external view returns (address) {
        return share;
    }

    function getPoolStore() external view returns (address) {
        return address(store);
    }

    function getPeriodFinish() external view returns (uint256) {
        return periodFinish;
    }

    function getStartTime() external view returns (uint256) {
        return startTime;
    }

    function getPeriod() external view returns (uint256) {
        return period;
    }

    function getRewardRate() external view returns (uint256) {
        return rewardRate;
    }

    function getRewardRateExtra() external view returns (uint256) {
        return rewardRateExtra;
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     *
     * @param _pid pool id
     * @param _crit reward rate
     */
    function _rewardRatePerPool(uint256 _pid, uint256 _crit) internal view returns (uint256) {
        uint256 totalWeight = store.totalWeight();
        if (totalWeight == 0) {
            return 0;
        }
        uint256 weight = store.weightOf(_pid);

        return _crit * weight / totalWeight;
    }

    function _updatePool(uint256 _pid) internal {
        if (block.timestamp < startTime) {
            return;
        }

        if (!pools[_pid].initialized) {
            pools[_pid] = Pool({
                initialized: true,
                rewardRate: rewardRate,
                lastUpdateTime: block.timestamp,
                rewardPerTokenStored: 0
            });
        }

        if (!stopped && block.timestamp >= periodFinish) {
            rewardRateBeforeHalve = rewardRate;
            rewardRate = rewardRate * HALVE_REWARD_RATE / MAX_REWARD_RATE;
            startTime = block.timestamp;
            periodFinish = block.timestamp + period;
        }

        Pool storage pool = pools[_pid];
        uint256 newRewardPerToken = rewardPerToken(_pid);

        if (newRewardPerToken != pool.rewardPerTokenStored) {
            pool.rewardPerTokenStored = newRewardPerToken;
        }

        if (pool.rewardRate == rewardRateBeforeHalve) {
            pool.rewardRate = rewardRate;
        }

        pool.lastUpdateTime = applicableRewardTime();
    }

    function _updateUser(uint256 _pid, address _target) internal {
        User storage user = users[_pid][_target];

        uint256 newReward = rewardEarned(_pid, _target);

        if (newReward != user.reward) {
            user.reward = newReward;
        }

        uint256 newRewardPerTokenPaid = pools[_pid].rewardPerTokenStored;
        if (newRewardPerTokenPaid != user.rewardPerTokenPaid) {
            user.rewardPerTokenPaid = newRewardPerTokenPaid;
        }
    }
}
