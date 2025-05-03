// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {TresuryState} from "src/treasury/TreasuryState.sol";

abstract contract SeigniorageProxy is Context, Ownable {
    error SeigniorageProxy__InvalidTreasury();
    error SeigniorageProxy__InvalidBoardroom();
    error SeigniorageProxy__InvalidBondroom();

    address public treasury;
    address public boardroom;
    address public bondroom;

    modifier onlyTreasury() {
        if (_msgSender() != treasury) revert SeigniorageProxy__InvalidTreasury();
        _;
    }

    modifier onlyBoardroom() {
        if (_msgSender() != boardroom) revert SeigniorageProxy__InvalidBoardroom();
        _;
    }

    modifier onlyBondroom() {
        if (_msgSender() != bondroom) revert SeigniorageProxy__InvalidBondroom();
        _;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setBoardroom(address _boardroom) public onlyOwner {
        boardroom = _boardroom;
    }
}
