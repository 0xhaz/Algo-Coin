// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Epoch} from "src/utils/Epoch.sol";

contract EpochTester is Test {
    Epoch public epoch;

    uint256 public constant DAY = 86400;
    uint256 public constant ETH = 1 ether;
    uint256 public constant ZERO = 0;

    address public operator = makeAddr("operator");

    function setUp() public {
        epoch = new Epoch(DAY, block.timestamp + DAY, 0);
    }

    function test_GetLastEpoch() public {
        uint256 currentTime = block.timestamp + DAY;
        uint256 lastEpoch = epoch.getLastEpoch();
        assertEq(lastEpoch, 0);

        vm.warp(currentTime + DAY);
        epoch.poke();
        lastEpoch = epoch.getLastEpoch();
        assertEq(lastEpoch, 1);

        vm.warp(currentTime + 2 * DAY + 1);
        epoch.poke();
        lastEpoch = epoch.getLastEpoch();
        assertEq(lastEpoch, 2);

        vm.warp(currentTime + 3 * DAY + 1);
        epoch.poke();
        lastEpoch = epoch.getLastEpoch();
        assertEq(lastEpoch, 3);
    }

    function test_GetCurrentEpoch() public {
        uint256 currentTime = block.timestamp + DAY;
        uint256 currentEpoch = epoch.getCurrentEpoch();
        assertEq(currentEpoch, 0);

        vm.warp(currentTime + DAY);
        epoch.poke();
        currentEpoch = epoch.getCurrentEpoch();
        assertEq(currentEpoch, 1);

        vm.warp(currentTime + 2 * DAY + 1);
        epoch.poke();
        currentEpoch = epoch.getCurrentEpoch();
        assertEq(currentEpoch, 2);

        vm.warp(currentTime + 3 * DAY + 1);
        epoch.poke();
        currentEpoch = epoch.getCurrentEpoch();
        assertEq(currentEpoch, 3);
    }

    function test_GetNextEpoch() public {
        uint256 currentTime = block.timestamp + DAY;
        uint256 nextEpoch = epoch.getNextEpoch();
        assertEq(nextEpoch, 1);

        vm.warp(currentTime + DAY);
        epoch.poke();
        nextEpoch = epoch.getNextEpoch();
        assertEq(nextEpoch, 2);

        vm.warp(currentTime + 2 * DAY + 1);
        epoch.poke();
        nextEpoch = epoch.getNextEpoch();
        assertEq(nextEpoch, 3);

        vm.warp(currentTime + 3 * DAY + 1);
        epoch.poke();
        nextEpoch = epoch.getNextEpoch();
        assertEq(nextEpoch, 4);
    }

    function test_RevertOn_InvalidStartTime() public {
        vm.expectRevert(Epoch.Epoch__InvalidStartTime.selector);
        new Epoch(DAY, block.timestamp - 1, 0);
    }

    function test_RevertWhen_PokeBeforeStartTime() public {
        vm.expectRevert(Epoch.Epoch__NotStartedYet.selector);
        epoch.poke();
    }

    function test_RevertWhen_PokeNotAllowed() public {
        uint256 startTime = block.timestamp + DAY;
        vm.warp(startTime + DAY);
        epoch.poke();
        assertEq(epoch.callable(), false);

        vm.expectRevert(Epoch.Epoch__NotAllowed.selector);
        epoch.poke();
    }

    function test_RevertWhen_NonOperatorSetPeriod() public {
        address nonOperator = makeAddr("nonOperator");
        vm.prank(nonOperator);
        vm.expectRevert();
        epoch.setPeriod(2 * DAY);
    }

    function test_RevertWhen_NonOperatorPoke() public {
        address nonOperator = makeAddr("nonOperator");
        vm.prank(nonOperator);
        vm.expectRevert();
        epoch.poke();
    }

    function test_Governance_SetPeriod() public {
        epoch.transferOperator(operator);
        vm.startPrank(operator);
        uint256 newPeriod = DAY * 2; // 2 days
        epoch.setPeriod(newPeriod);
        assertEq(epoch.getPeriod(), newPeriod);
        vm.stopPrank();
    }
}
