// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

contract MockPool {
    event Updated(uint256 indexed _pid);

    address[] public tokens;
    mapping(address => uint256) public index;

    function addPool(address _token) public {
        uint256 i = tokens.length;
        tokens.push(_token);
        index[_token] = i;
    }

    function update(uint256 _pid) public {
        emit Updated(_pid);
    }
}
