// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

interface ICurve {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event MinSupplyChanged(address indexed operator, uint256 _old, uint256 _new);
    event MaxSupplyChanged(address indexed operator, uint256 _old, uint256 _new);
    event MinCeilingChanged(address indexed operator, uint256 _old, uint256 _new);
    event MaxCeilingChanged(address indexed operator, uint256 _old, uint256 _new);

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function minSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function minCeiling() external view returns (uint256);

    function maxCeiling() external view returns (uint256);

    function calcCeiling(uint256 supply) external view returns (uint256);
}
