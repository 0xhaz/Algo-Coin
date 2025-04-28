// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPoolStore} from "../interfaces/IPoolStore.sol";
import {IPoolStoreGov} from "../interfaces/IPoolStoreGov.sol";

import {Operator} from "../access/Operator.sol";

contract PoolStore is IPoolStore, IPoolStoreGov, Operator {
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public override totalWeight = 0;

    Pool[] public pools;

    mapping(uint256 => mapping(address => uint256)) s_balances;
    mapping(address => uint256[]) public s_indexByToken;

    bool public emergency = false;
    address public weightFeeder;

    /*//////////////////////////////////////////////////////////////
                                STRUCTURES
    //////////////////////////////////////////////////////////////*/

    struct Pool {
        string name;
        IERC20 token;
        uint256 weight;
        uint256 totalSupply;
    }

    /*//////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() Operator() {
        weightFeeder = _msgSender();
    }

    /*//////////////////////////////////////////////////////////////
                                  MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier onlyWeightFeeder() {
        if (_msgSender() != weightFeeder) revert PoolStore__CallerIsNotOwner();
        _;
    }

    modifier checkPoolId(uint256 _pid) {
        if (_pid >= pools.length) revert PoolStore__InvalidPoolId();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                  GOVERNANCE
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
    function resolveEmergency() public override onlyOwner {
        emergency = false;

        emit EmergencyResolved(msg.sender);
    }

    /**
     *
     * @param _newFeeder The new address of the weight feeder
     */
    function setWeightFeeder(address _newFeeder) public override onlyOwner {
        address oldFeeder = weightFeeder;
        weightFeeder = _newFeeder;

        emit WeightFeederChanged(_msgSender(), oldFeeder, _newFeeder);
    }

    /**
     *
     * @param _name The name of the pool
     * @param _token  The address of the token contract
     * @param _weight  The weight of the pool
     */
    function addPool(string memory _name, IERC20 _token, uint256 _weight) public override onlyOwner {
        totalWeight += _weight;

        uint256 index = pools.length;
        s_indexByToken[address(_token)].push(index);

        pools.push(Pool({name: _name, token: _token, weight: _weight, totalSupply: 0}));

        emit PoolAdded(_msgSender(), index, _name, address(_token), _weight);
    }

    /**
     * @param _pid The id of the pool
     * @param _weight The weight of the pool
     */
    function setPool(uint256 _pid, uint256 _weight) public override onlyWeightFeeder checkPoolId(_pid) {
        Pool memory pool = pools[_pid];

        uint256 oldWeight = pool.weight;
        totalWeight = totalWeight + _weight - oldWeight;
        pool.weight = _weight;

        pools[_pid] = pool;

        emit PoolWeightChanged(_msgSender(), _pid, oldWeight, _weight);
    }

    /**
     * @param _pid The id of the pool
     * @param _name The name of the pool
     */
    function setPoolName(uint256 _pid, string memory _name) public override checkPoolId(_pid) onlyOwner {
        string memory oldName = pools[_pid].name;
        pools[_pid].name = _name;

        emit PoolNameChanged(_msgSender(), _pid, oldName, _name);
    }

    /*//////////////////////////////////////////////////////////////
                                  CALLS
    //////////////////////////////////////////////////////////////*/
    /**
     * @return total pool length
     */
    function poolLength() public view override returns (uint256) {
        return pools.length;
    }

    /**
     * @param _token pool token address
     * @return pool ids
     */
    function poolIdsOf(address _token) public view override returns (uint256[] memory) {
        return s_indexByToken[_token];
    }

    /**
     * @param _pid pool id
     * @return pool name
     */
    function nameOf(uint256 _pid) public view override checkPoolId(_pid) returns (string memory) {
        return pools[_pid].name;
    }

    /**
     * @param _pid pool id
     * @return pool token address
     */
    function tokenOf(uint256 _pid) public view override checkPoolId(_pid) returns (address) {
        return address(pools[_pid].token);
    }

    /**
     * @param _pid pool id
     * @return pool weight
     */
    function weightOf(uint256 _pid) public view override checkPoolId(_pid) returns (uint256) {
        return pools[_pid].weight;
    }

    /**
     * @param _pid pool id
     * @return total staked token amount
     */
    function totalSupply(uint256 _pid) public view override checkPoolId(_pid) returns (uint256) {
        return pools[_pid].totalSupply;
    }

    /**
     * @param _pid pool id
     * @param _sender staker address
     * @return staked token amount
     */
    function balanceOf(uint256 _pid, address _sender) public view override checkPoolId(_pid) returns (uint256) {
        return s_balances[_pid][_sender];
    }

    /*//////////////////////////////////////////////////////////////
                    TRANSACTIONS - OPERATOR ONLY
    //////////////////////////////////////////////////////////////*/
    /**
     * @param _pid pool id
     * @param _owner staker address
     * @param _amount staked token amount
     */
    function deposit(uint256 _pid, address _owner, uint256 _amount) public override onlyOperator checkPoolId(_pid) {
        pools[_pid].totalSupply += _amount;
        s_balances[_pid][_owner] += _amount;
        IERC20(tokenOf(_pid)).safeTransferFrom(_msgSender(), address(this), _amount);

        emit Deposit(_msgSender(), _owner, _pid, _amount);
    }

    /**
     * @param _pid pool id
     * @param _owner staker address
     * @param _amount staked token amount
     */
    function withdraw(uint256 _pid, address _owner, uint256 _amount) public override onlyOperator checkPoolId(_pid) {
        _withdraw(_pid, _owner, _amount);
    }

    /**
     *
     * @notice Anyone can withdraw its balance even if is not the operator
     * @param _pid pool id
     */
    function emergencyWithdraw(uint256 _pid) public override checkPoolId(_pid) {
        if (!emergency) revert PoolStore__NotInEmergency();

        _withdraw(_pid, _msgSender(), s_balances[_pid][_msgSender()]);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _pid pool id
     * @param _owner staker address
     * @param _amount staked token amount
     */
    function _withdraw(uint256 _pid, address _owner, uint256 _amount) internal {
        pools[_pid].totalSupply -= _amount;
        s_balances[_pid][_owner] -= _amount;
        IERC20(tokenOf(_pid)).safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), _owner, _pid, _amount);
    }
}
