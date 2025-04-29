// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PoolStore, IERC20} from "../../src/distribution/PoolStore.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract PoolStoreTest is Test {
    PoolStore public poolStore;

    address public operator = makeAddr("operator");
    address public alice = makeAddr("alice");

    ERC20Mock public mockToken;

    function setUp() public {
        vm.startPrank(operator);
        poolStore = new PoolStore();
        vm.stopPrank();

        mockToken = new ERC20Mock();
    }

    function test_Governance() public {
        address newPool = address(0x123);
        IERC20 newToken = IERC20(address(0x456));
        uint256 newWeight = 1000;
        string memory newName = "New Pool";
        vm.startPrank(operator);

        poolStore.reportEmergency();
        assertTrue(poolStore.emergency());

        poolStore.resolveEmergency();
        assertFalse(poolStore.emergency());

        poolStore.setWeightFeeder(newPool);
        assertEq(poolStore.weightFeeder(), newPool);

        poolStore.addPool(newName, newToken, newWeight);
        (string memory poolName, IERC20 token, uint256 weight, uint256 totalSupply) = poolStore.pools(0);
        assertEq(poolName, newName);
        assertEq(address(token), address(newToken));
        assertEq(weight, newWeight);
        assertEq(totalSupply, 0);

        vm.startPrank(newPool);

        poolStore.setPool(0, 2000);
        (poolName, token, weight, totalSupply) = poolStore.pools(0);
        assertEq(weight, 2000);
        assertEq(totalSupply, 0);
        assertEq(poolStore.poolLength(), 1);
        assertEq(poolStore.poolIdsOf(address(newToken)).length, 1);

        vm.stopPrank();

        vm.startPrank(operator);
        poolStore.setPoolName(0, "Updated Pool");
        (poolName, token, weight, totalSupply) = poolStore.pools(0);
        assertEq(poolName, "Updated Pool");
        assertEq(weight, 2000);
        assertEq(totalSupply, 0);
        assertEq(poolStore.nameOf(0), "Updated Pool");
        assertEq(poolStore.tokenOf(0), address(newToken));
        assertEq(poolStore.weightOf(0), 2000);
        assertEq(poolStore.totalSupply(0), 0);
        vm.stopPrank();
    }

    function test_DepositWithdraw() public {
        vm.startPrank(operator);
        poolStore.addPool("Test Pool", IERC20(address(mockToken)), 1000);

        vm.deal(address(mockToken), 100);
        mockToken.mint(operator, 100);
        mockToken.approve(address(poolStore), type(uint256).max);
        poolStore.deposit(0, operator, 100);
        assertEq(poolStore.balanceOf(0, operator), 100);
        assertEq(poolStore.totalSupply(0), 100);

        poolStore.withdraw(0, operator, 50);
        assertEq(poolStore.balanceOf(0, operator), 50);
        assertEq(poolStore.totalSupply(0), 50);

        vm.stopPrank();
    }
}
