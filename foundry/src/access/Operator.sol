// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Operator is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Operator__CallerIsNotOperator();
    error Operator__ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address private s_operator;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOperator() {
        if (s_operator != _msgSender()) revert Operator__CallerIsNotOperator();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(_msgSender()) {
        s_operator = _msgSender();
        emit OperatorTransferred(address(0), s_operator);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _transferOperator(address newOperator_) internal {
        if (newOperator_ == address(0)) revert Operator__ZeroAddress();

        emit OperatorTransferred(address(s_operator), newOperator_);
        s_operator = newOperator_;
    }

    /*//////////////////////////////////////////////////////////////
                              PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    function operator() public view returns (address) {
        return s_operator;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == s_operator;
    }
}
