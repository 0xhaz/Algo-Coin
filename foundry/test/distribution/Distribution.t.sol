// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Distribution, IPool} from "src/distribution/Distribution.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PoolStore} from "src/distribution/PoolStore.sol";
import {Share} from "src/assets/Share.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DistributionTest is Test {
    Distribution public distribution;
    PoolStore public poolStore;
    Share public share;

    ERC20Mock public tokenA;
    ERC20Mock public tokenB;
    ERC20Mock public tokenC;

    address[] public tokens;

    uint256 public constant INITIAL_DEPOSIT = 1e18;
    uint256 public constant REWARD = INITIAL_DEPOSIT * 3000;
    uint256 public constant POOL_START_OFFSET = 200;
    uint256 public constant POOL_PERIOD = 30 days;

    address public operator = makeAddr("operator");
    address public alice = makeAddr("alice");

    function setUp() public {
        vm.startPrank(operator);
        share = new Share();
        poolStore = new PoolStore();
        distribution = new Distribution(address(share), address(poolStore));

        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
        tokenC = new ERC20Mock();
        tokens = [address(tokenA), address(tokenB), address(tokenC)];

        poolStore.addPool("Token A Pool", tokenA, INITIAL_DEPOSIT);
        poolStore.addPool("Token B Pool", tokenB, INITIAL_DEPOSIT * 2);
        poolStore.addPool("Token C Pool", tokenC, INITIAL_DEPOSIT * 3);

        poolStore.transferOperator(address(distribution));

        share.mint(address(distribution), REWARD * 7 / 4); // 1.75x the reward
        vm.stopPrank();

        vm.startPrank(address(distribution));
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20Mock(tokens[i]).approve(address(poolStore), type(uint256).max);
        }
        vm.stopPrank();

        vm.startPrank(alice);
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20Mock(tokens[i]).mint(alice, INITIAL_DEPOSIT * 3);
            ERC20Mock(tokens[i]).approve(address(poolStore), type(uint256).max);
            ERC20Mock(tokens[i]).approve(address(distribution), type(uint256).max);
            distribution.deposit(i, INITIAL_DEPOSIT);
        }
        vm.stopPrank();
    }

    function test_RewardInitilization() public {
        vm.startPrank(operator);
        uint256 startTime = block.timestamp + POOL_START_OFFSET;

        distribution.setPeriod(startTime, POOL_PERIOD);
        distribution.setReward(REWARD);

        assertEq(distribution.getRewardRate(), REWARD / POOL_PERIOD);
        assertEq(distribution.getStartTime(), startTime);
        assertEq(distribution.getPeriodFinish(), startTime + POOL_PERIOD);
        assertEq(distribution.getPeriod(), POOL_PERIOD);
        assertEq(distribution.getShare(), address(share));
        assertEq(distribution.getPoolStore(), address(poolStore));
        assertEq(distribution.tokenOf(0), address(tokenA));
        assertEq(distribution.poolIdsOf(address(tokenA))[0], 0);
        assertEq(distribution.totalSupply(0), INITIAL_DEPOSIT);
        assertEq(distribution.balanceOf(0, alice), INITIAL_DEPOSIT);
        assertEq(distribution.getHalvingRewardRate(), 75e18);
        assertEq(distribution.getRewardRateBeforeHalve(), 0);
        assertEq(distribution.getRewardRateExtra(), 0);
        assertEq(distribution.getMaxRewardRate(), 100e18);

        vm.stopPrank();
    }

    function test_RewardOnUserDeposit() public {
        vm.startPrank(operator);
        uint256 startTime = block.timestamp;
        distribution.setPeriod(startTime, POOL_PERIOD);
        distribution.setReward(REWARD);

        uint256[] memory poolIds = new uint256[](3);
        poolIds[0] = 0;
        poolIds[1] = 1;
        poolIds[2] = 2;

        distribution.massUpdate(poolIds);
        vm.stopPrank();

        for (uint256 i; i < poolIds.length; i++) {
            uint256 pid = poolIds[i];
            assertEq(distribution.rewardPerToken(pid), 0);
            assertEq(distribution.rewardEarned(pid, alice), 0);
        }

        assertEq(distribution.getRewardRateBeforeHalve(), 0);

        uint256 warptime = block.timestamp + POOL_START_OFFSET;
        vm.warp(startTime + POOL_START_OFFSET);

        vm.startPrank(alice);
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            vm.expectEmit(true, true, false, true);
            emit IPool.DepositToken(alice, i, INITIAL_DEPOSIT);
            distribution.deposit(i, INITIAL_DEPOSIT);

            assertEq(token.balanceOf(alice), INITIAL_DEPOSIT);
            assertEq(token.balanceOf(address(poolStore)), INITIAL_DEPOSIT * 2);
        }

        for (uint256 i = 0; i < poolIds.length; i++) {
            distribution.update(poolIds[i]);

            uint256 earned = distribution.rewardEarned(poolIds[i], alice);
            console.log("PID", poolIds[i], "Reward Earned", earned);

            uint256 poolWeight = poolStore.weightOf(poolIds[i]);
            uint256 totalWeight = poolStore.totalWeight();
            uint256 expected = REWARD * warptime * poolWeight / totalWeight / POOL_PERIOD;

            assertApproxEqAbs(earned, expected, 1e15);
        }

        vm.stopPrank();
    }

    function test_FullReward() public {
        vm.startPrank(operator);
        uint256 startTime = block.timestamp;
        distribution.setPeriod(startTime, POOL_PERIOD);
        distribution.setReward(REWARD);
        vm.stopPrank();

        vm.startPrank(operator);
        distribution.setExtraRewardRate(REWARD / POOL_PERIOD);
        vm.stopPrank();

        vm.warp(startTime + POOL_START_OFFSET);
        vm.startPrank(alice);
        for (uint256 i = 0; i < tokens.length; i++) {
            distribution.deposit(i, INITIAL_DEPOSIT);
        }
        vm.stopPrank();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 poolRate = distribution.rewardRatePerPool(i);
            console.log("Pool Rate", poolRate);
            uint256 expected =
                (REWARD / POOL_PERIOD + REWARD / POOL_PERIOD) * poolStore.weightOf(i) / poolStore.totalWeight();
            console.log("Expected", expected);

            assertEq(poolRate, expected);
        }

        vm.warp(startTime + POOL_START_OFFSET + 2 days);
        vm.startPrank(alice);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 earned = distribution.rewardEarned(i, alice);
            assertGt(earned, 0);

            uint256 balanceBefore = IERC20(share).balanceOf(alice);
            distribution.claimReward(i);
            uint256 balanceAfter = IERC20(share).balanceOf(alice);
            assertEq(balanceAfter, balanceBefore + earned);
        }
        vm.stopPrank();

        vm.startPrank(alice);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balanceBefore = IERC20(tokens[i]).balanceOf(alice);
            vm.expectEmit(true, true, false, true);
            emit IPool.WithdrawToken(alice, i, INITIAL_DEPOSIT);
            distribution.withdraw(i, INITIAL_DEPOSIT);

            uint256 balanceAfter = IERC20(tokens[i]).balanceOf(alice);
            assertEq(balanceAfter, balanceBefore + INITIAL_DEPOSIT);
        }
        vm.stopPrank();

        vm.startPrank(operator);
        distribution.stop();
        assertEq(distribution.getPeriodFinish(), block.timestamp);

        Distribution newPool = new Distribution(address(share), address(poolStore));
        newPool.transferOperator(address(distribution));

        share.mint(address(distribution), REWARD);

        distribution.migrate(address(newPool), REWARD);
        vm.stopPrank();

        assertEq(IERC20(share).balanceOf(address(newPool)), REWARD);
    }

    function test_DepositAndExit() public {
        vm.startPrank(operator);
        uint256 startTime = block.timestamp;
        distribution.setPeriod(startTime, POOL_PERIOD);
        distribution.setReward(REWARD);
        vm.stopPrank();

        vm.startPrank(operator);
        distribution.setExtraRewardRate(REWARD / POOL_PERIOD);
        vm.stopPrank();

        vm.warp(startTime + POOL_START_OFFSET);
        vm.startPrank(alice);
        for (uint256 i = 0; i < tokens.length; i++) {
            distribution.deposit(i, INITIAL_DEPOSIT);
        }
        vm.stopPrank();

        vm.warp(startTime + POOL_START_OFFSET + 20 days);

        vm.startPrank(alice);
        for (uint256 i = 0; i < tokens.length; i++) {
            distribution.exit(i);

            uint256 balanceAfter = IERC20(tokens[i]).balanceOf(alice);
            assertEq(balanceAfter, INITIAL_DEPOSIT * 3);
        }
        vm.stopPrank();
    }
}
