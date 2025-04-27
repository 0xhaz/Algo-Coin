// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BoardroomV2} from "src/boardroom/Boardroom.sol";
import {Operator} from "src/access/Operator.sol";
import {IBoardroomV2} from "src/interfaces/IBoardroomV2.sol";
import {IBoardroomV2Gov} from "src/interfaces/IBoardroomV2Gov.sol";
import {IRewardPool} from "src/interfaces/IRewardPool.sol";
import {TokenStore, ITokenStore, Operator, ITokenStoreGov} from "../../src/boardroom/TokenStore.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockDai is ERC20 {
    constructor() ERC20("MockDai", "mDAI") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract MockBoardroomPool is IRewardPool {
    address public rewardToken;
    uint256 public amount;
    uint256 public times;
    bool public errorOnCollect;
    uint256 public collected;

    constructor(address _rewardToken, uint256 _amount, uint256 _times, bool _errorOnCollect) {
        rewardToken = _rewardToken;
        amount = _amount;
        times = _times;
        errorOnCollect = _errorOnCollect;
    }

    function collect() external override returns (address, uint256) {
        if (errorOnCollect) {
            revert("Pool: nonono");
        }
        if (collected < times) {
            collected++;
            IERC20(rewardToken).transfer(msg.sender, amount);
            return (rewardToken, amount);
        }
        return (rewardToken, 0);
    }
}

contract BoardroomTest is Test {
    BoardroomV2 public boardroom;
    TokenStore public store;
    MockDai public cash;
    MockDai public share;
    MockBoardroomPool public sharePool;
    MockBoardroomPool public shareErrPool;

    address operator = makeAddr("operator");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    address[] public users;
    address[] public tokens;

    uint256 public constant INITIAL_AMOUNT = 1e18;

    function setUp() public {
        share = new MockDai();
        cash = new MockDai();
        store = new TokenStore(address(share));

        store.transferOwnership(operator);

        share.mint(operator, INITIAL_AMOUNT * 100);
        share.mint(alice, INITIAL_AMOUNT * 100);
        share.mint(bob, INITIAL_AMOUNT * 100);

        vm.startPrank(operator);

        sharePool = new MockBoardroomPool(address(share), INITIAL_AMOUNT / 2, 1, false);
        shareErrPool = new MockBoardroomPool(address(share), 0, 1, true);

        boardroom = new BoardroomV2(address(cash), address(share), address(store));

        store.transferOperator(address(boardroom));

        assertEq(store.operator(), address(boardroom));

        share.approve(address(boardroom), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(alice);
        share.approve(address(boardroom), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        share.approve(address(boardroom), type(uint256).max);
        vm.stopPrank();
    }

    function test_CanDepositAndWithdrawWithoutPools() public {
        vm.startPrank(operator);

        boardroom.migrate();

        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2.DepositShare(operator, INITIAL_AMOUNT);
        boardroom.deposit(INITIAL_AMOUNT);
        assertEq(boardroom.totalSupply(), INITIAL_AMOUNT);
        assertEq(boardroom.balanceOf(operator), INITIAL_AMOUNT);

        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2.WithdrawShare(operator, INITIAL_AMOUNT);
        boardroom.withdraw(INITIAL_AMOUNT);
        vm.stopPrank();
    }

    function test_CommonFlowWithPools() public {
        vm.startPrank(operator);

        boardroom.migrate();
        boardroom.addRewardToken(address(share));
        boardroom.addRewardPool(address(sharePool));
        boardroom.addRewardPool(address(shareErrPool));

        share.mint(address(sharePool), INITIAL_AMOUNT);
        share.mint(address(shareErrPool), INITIAL_AMOUNT);

        vm.expectEmit(true, true, false, true);
        emit ITokenStore.Deposit(address(boardroom), operator, INITIAL_AMOUNT);

        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2.DepositShare(operator, INITIAL_AMOUNT);

        boardroom.deposit(INITIAL_AMOUNT);

        vm.expectEmit(true, true, false, true);
        emit ITokenStore.Deposit(address(boardroom), operator, INITIAL_AMOUNT); // TokenStore Deposit

        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2.DepositShare(operator, INITIAL_AMOUNT); // BoardroomV2 DepositShare

        boardroom.deposit(INITIAL_AMOUNT);

        vm.expectEmit(true, true, false, true);
        emit ITokenStore.Withdraw(address(boardroom), operator, INITIAL_AMOUNT); // <--- TokenStore Withdraw

        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2.WithdrawShare(operator, INITIAL_AMOUNT); // <--- BoardroomV2 WithdrawShare

        boardroom.withdraw(INITIAL_AMOUNT);

        boardroom.claimReward();

        vm.stopPrank();
    }

    function test_CanClaimRewardCorrectly() public {
        vm.startPrank(operator);

        boardroom.migrate();
        boardroom.addRewardToken(address(share));

        assertEq(boardroom.rewardTokenAt(0), address(cash));
        assertEq(boardroom.rewardTokenAt(1), address(share));

        boardroom.addRewardPool(address(sharePool));

        assertEq(boardroom.rewardPoolsAt(0), address(sharePool));

        boardroom.addRewardPool(address(shareErrPool));

        assertEq(boardroom.rewardPoolsLength(), 2); // sharePool, shareErrPool

        share.mint(address(sharePool), INITIAL_AMOUNT);
        share.mint(address(shareErrPool), INITIAL_AMOUNT);

        share.approve(address(boardroom), type(uint256).max);

        boardroom.deposit(INITIAL_AMOUNT);

        assertEq(boardroom.lastSnapshotIndex(address(share)), 1);

        boardroom.collectReward();

        assertEq(boardroom.lastSnapshotIndex(address(share)), 2);

        uint256 earned = boardroom.rewardEarned(address(share), operator);
        assertEq(earned, INITIAL_AMOUNT / 2);

        uint256 beforeBalance = share.balanceOf(operator);

        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2.RewardClaimed(operator, address(share), INITIAL_AMOUNT / 2);

        boardroom.claimReward();

        uint256 afterBalance = share.balanceOf(operator);

        assertEq(afterBalance - beforeBalance, INITIAL_AMOUNT / 2);
        vm.stopPrank();
    }

    function test_GovFunctions() public {
        vm.startPrank(operator);

        // migrate
        assertFalse(boardroom.migrated());
        boardroom.migrate();
        assertTrue(boardroom.migrated());

        // add reward token
        address newRewardToken = address(new MockDai());
        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2Gov.RewardTokenAdded(operator, newRewardToken);
        boardroom.addRewardToken(newRewardToken);
        assertEq(boardroom.rewardTokensLength(), 3); // cash, share, newRewardToken

        // remove reward token
        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2Gov.RewardTokenRemoved(operator, newRewardToken);
        boardroom.removeRewardToken(newRewardToken);
        assertEq(boardroom.rewardTokensLength(), 2); // cash, share

        // add reward pool
        address newRewardPool = address(1234);
        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2Gov.RewardPoolAdded(operator, newRewardPool);
        boardroom.addRewardPool(newRewardPool);
        assertEq(boardroom.rewardPoolsLength(), 1);

        // remove reward pool
        vm.expectEmit(true, true, false, true);
        emit IBoardroomV2Gov.RewardPoolRemoved(operator, newRewardPool);
        boardroom.removeRewardPool(newRewardPool);
        assertEq(boardroom.rewardPoolsLength(), 0);

        vm.stopPrank();
    }

    function test_GovFunctions_RevertIfNotOwner() public {
        vm.startPrank(alice);

        // migrate
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        boardroom.migrate();

        // add reward token
        address newRewardToken = address(new MockDai());
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        boardroom.addRewardToken(newRewardToken);

        // remove reward token
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        boardroom.removeRewardToken(newRewardToken);

        // add reward pool
        address newRewardPool = address(1234);
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        boardroom.addRewardPool(newRewardPool);

        // remove reward pool
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        boardroom.removeRewardPool(newRewardPool);

        vm.stopPrank();
    }
}
