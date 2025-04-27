// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TokenStore, ITokenStore, Operator, ITokenStoreGov} from "../../src/boardroom/TokenStore.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TokenStoreTest is Test {
    ERC20Mock public token;
    TokenStore public tokenStore;

    address operator = makeAddr("operator");
    address ant = makeAddr("ant");
    address whale = makeAddr("whale");

    uint256 public constant INITIAL_BALANCE = 1e18;

    function setUp() public {
        vm.startPrank(operator);
        token = new ERC20Mock();
        tokenStore = new TokenStore(address(token));
        tokenStore.transferOperator(operator);

        token.mint(operator, INITIAL_BALANCE * 2);
        token.mint(whale, INITIAL_BALANCE);

        token.approve(address(tokenStore), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(whale);
        token.approve(address(tokenStore), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(ant);
        token.approve(address(tokenStore), type(uint256).max);
        vm.stopPrank();
    }

    function test_CommonFlow() public {
        assertEq(tokenStore.totalSupply(), 0);
        assertEq(tokenStore.balanceOf(operator), 0);

        vm.startPrank(operator);
        vm.expectEmit(true, true, false, true);
        emit ITokenStore.Deposit(operator, operator, INITIAL_BALANCE);
        tokenStore.deposit(operator, INITIAL_BALANCE);
        vm.stopPrank();

        vm.prank(ant);
        vm.expectRevert(Operator.Operator__CallerIsNotOperator.selector);
        tokenStore.deposit(ant, INITIAL_BALANCE);

        vm.prank(whale);
        vm.expectRevert(Operator.Operator__CallerIsNotOperator.selector);
        tokenStore.deposit(whale, INITIAL_BALANCE);

        assertEq(tokenStore.totalSupply(), INITIAL_BALANCE);
        assertEq(tokenStore.balanceOf(operator), INITIAL_BALANCE);

        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit ITokenStore.Withdraw(operator, operator, INITIAL_BALANCE);
        tokenStore.withdraw(operator, INITIAL_BALANCE);

        assertEq(tokenStore.totalSupply(), 0);
        assertEq(tokenStore.balanceOf(operator), 0);

        vm.prank(ant);
        vm.expectRevert(Operator.Operator__CallerIsNotOperator.selector);
        tokenStore.withdraw(ant, INITIAL_BALANCE);

        vm.prank(whale);
        vm.expectRevert(Operator.Operator__CallerIsNotOperator.selector);
        tokenStore.withdraw(whale, INITIAL_BALANCE);

        vm.startPrank(operator);
        tokenStore.deposit(ant, INITIAL_BALANCE);

        assertEq(tokenStore.balanceOf(ant), INITIAL_BALANCE);

        tokenStore.reportEmergency();
        uint256 balanceBefore = token.balanceOf(ant);
        tokenStore.emergencyWithdraw();
        uint256 balanceAfter = token.balanceOf(ant);

        assertEq(balanceAfter - balanceBefore, 0);
        assertEq(tokenStore.balanceOf(ant), INITIAL_BALANCE);
        assertEq(tokenStore.balanceOf(operator), 0);
        vm.stopPrank();
    }

    function test_GovEmergencyResolve() public {
        vm.startPrank(operator);
        tokenStore.deposit(ant, INITIAL_BALANCE);
        assertEq(tokenStore.balanceOf(ant), INITIAL_BALANCE);

        assertFalse(tokenStore.getEmergencyStatus());

        tokenStore.reportEmergency();

        vm.expectEmit(true, false, false, false);
        emit ITokenStoreGov.EmergencyReported(operator);
        tokenStore.reportEmergency();

        assertTrue(tokenStore.getEmergencyStatus());
        vm.stopPrank();

        vm.startPrank(ant);
        tokenStore.emergencyWithdraw();
        assertEq(tokenStore.balanceOf(ant), 0);
        assertEq(token.balanceOf(ant), INITIAL_BALANCE);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectEmit(true, false, false, false);
        emit ITokenStoreGov.EmergencyResolved(operator);
        tokenStore.resolveEmergency();

        assertFalse(tokenStore.getEmergencyStatus());
        vm.stopPrank();

        vm.startPrank(ant);
        vm.expectRevert(TokenStore.TokenStore__NotInEmergency.selector);
        tokenStore.emergencyWithdraw();
        vm.stopPrank();
    }

    function test_GovSetToken() public {
        vm.startPrank(operator);

        ERC20Mock newToken = new ERC20Mock();
        newToken.mint(operator, INITIAL_BALANCE * 2);
        newToken.approve(address(tokenStore), type(uint256).max);

        vm.expectEmit(true, true, false, true);
        emit ITokenStoreGov.TokenChanged(operator, address(newToken), address(token));
        tokenStore.setToken(address(newToken));

        tokenStore.deposit(operator, INITIAL_BALANCE);

        assertEq(tokenStore.token(), address(newToken));
        assertEq(tokenStore.totalSupply(), INITIAL_BALANCE);
        assertEq(tokenStore.balanceOf(operator), INITIAL_BALANCE);
    }
}
