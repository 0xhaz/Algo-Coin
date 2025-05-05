// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Operator} from "src/access/Operator.sol";

contract VoteProxy is Operator {
    /*//////////////////////////////////////////////////////////
                        EVENTS
    //////////////////////////////////////////////////////////*/
    event BoardroomChanged(address indexed operator, address indexed oldBoardroom, address indexed newBoardroom);

    /*//////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////*/
    address public boardroom;

    constructor(address _boardroom) {
        boardroom = _boardroom;
    }

    /*//////////////////////////////////////////////////////////
                        PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////*/
    function setBoardroom(address _boardroom) public onlyOperator {
        address oldBoardroom = boardroom;
        boardroom = _boardroom;
        emit BoardroomChanged(msg.sender, oldBoardroom, _boardroom);
    }

    /*//////////////////////////////////////////////////////////
                        VIEW / PURE FUNCTIONS
    //////////////////////////////////////////////////////////*/
    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "BAS in Boardroom";
    }

    function symbol() external pure returns (string memory) {
        return "BAS";
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(boardroom).totalSupply();
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return IERC20(boardroom).balanceOf(_owner);
    }
}
