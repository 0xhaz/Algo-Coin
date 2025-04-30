// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasisAsset is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);

    function burnFrom(address from, uint256 amount) external returns (bool);

    function operator() external view returns (address);

    function isOperator() external view returns (bool);
}
