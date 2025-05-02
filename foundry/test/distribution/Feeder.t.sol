// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Feeder} from "src/distribution/Feeder.sol";
import {ShareV2} from "src/assets/ShareV2.sol";
import {Share} from "src/assets/Share.sol";
import {PoolStore} from "src/distribution/PoolStore.sol";
import {MockBoardroom} from "test/mocks/MockBoardroom.sol";
import {MockPool} from "test/mocks/MockPool.sol";

contract FeederTest is Test {
    Feeder public feeder;
    ShareV2 public shareV2;
    Share public BAC_DAI_V1;
    Share public BAS_DAI_V1;
    MockBoardroom public boardroom;
    MockPool public shareV2Pool;
    PoolStore public shareV2PoolStore;
    ERC20Mock public shareV2LP;

    address public operator = makeAddr("operator");
    address public alice = makeAddr("alice");

    function setUp() public {
        vm.startPrank(operator);
        shareV2 = new ShareV2();
        BAC_DAI_V1 = new Share();
        BAS_DAI_V1 = new Share();
        boardroom = new MockBoardroom();
        shareV2PoolStore = new PoolStore();
        feeder = new Feeder();
        shareV2Pool = new MockPool();
        shareV2LP = new ERC20Mock();

        BAC_DAI_V1.mint(address(operator), 100 ether);
        BAS_DAI_V1.mint(address(operator), 100 ether);

        shareV2Pool.addPool(address(shareV2));
        shareV2Pool.addPool(address(shareV2LP));

        shareV2PoolStore.addPool("BASv2 Pool", shareV2, 1 ether);
        shareV2PoolStore.addPool("BASv2 LP Pool", shareV2LP, 0);

        shareV2PoolStore.transferOwnership(address(feeder));

        vm.stopPrank();
    }
}
