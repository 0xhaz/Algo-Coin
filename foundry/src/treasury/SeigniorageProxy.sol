// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {TreasuryState} from "src/treasury/TreasuryState.sol";

abstract contract SeigniorageProxyGov is Context, Ownable {
    error SeigniorageProxyGov__InvalidTreasury();
    error SeigniorageProxyGov__InvalidBoardroom();
    error SeigniorageProxyGov__InvalidBondroom();

    address public treasury;
    address public boardroom;
    address public bondroom;

    modifier onlyTreasury() {
        if (_msgSender() != treasury) revert SeigniorageProxyGov__InvalidTreasury();
        _;
    }

    modifier onlyBoardroom() {
        if (_msgSender() != boardroom) revert SeigniorageProxyGov__InvalidBoardroom();
        _;
    }

    modifier onlyBondroom() {
        if (_msgSender() != bondroom) revert SeigniorageProxyGov__InvalidBondroom();
        _;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setBoardroom(address _boardroom) public onlyOwner {
        boardroom = _boardroom;
    }
}

contract SeigniorageProxy is SeigniorageProxyGov {
    using SafeERC20 for IERC20;

    constructor(address _treasury, address _boardroom, address _bondroom) Ownable(_msgSender()) {
        treasury = _treasury;
        boardroom = _boardroom;
        bondroom = _bondroom;
    }

    function allocateSeigniorage(uint256 _total) public onlyTreasury {
        IERC20(TreasuryState(treasury).cash()).safeTransferFrom(_msgSender(), address(this), _total);
    }

    function collect() public onlyBoardroom returns (address, uint256) {
        address token = TreasuryState(treasury).cash();
        uint256 amount = IERC20(token).balanceOf(address(this));

        IERC20(token).safeTransfer(_msgSender(), amount);

        return (token, amount);
    }

    function emergencyWithdraw(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), _amount);
    }
}
