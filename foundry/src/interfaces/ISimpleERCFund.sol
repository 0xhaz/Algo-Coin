// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface ISimpleERCFund {
    event Deposit(address indexed from, uint256 indexed at, string reason);
    event Withdrawal(address indexed from, address indexed to, uint256 indexed at, string reason);

    function deposit(address token, uint256 amount, string memory reason) external;
    function withdraw(address token, uint256 amount, address to, string memory reason) external;
}
