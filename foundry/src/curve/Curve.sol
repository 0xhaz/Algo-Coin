// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ICurve} from "../interfaces/ICurve.sol";

abstract contract Curve is ICurve {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public override minSupply;
    uint256 public override maxSupply;

    uint256 public override minCeiling;
    uint256 public override maxCeiling;

    /*//////////////////////////////////////////////////////////////
                            GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    function setMinSupply(uint256 _newMinSupply) public virtual {
        uint256 oldMinSupply = minSupply;
        minSupply = _newMinSupply;
        emit MinSupplyChanged(msg.sender, oldMinSupply, _newMinSupply);
    }

    function setMaxSupply(uint256 _newMaxSupply) public virtual {
        uint256 oldMaxSupply = maxSupply;
        maxSupply = _newMaxSupply;
        emit MaxSupplyChanged(msg.sender, oldMaxSupply, _newMaxSupply);
    }

    function setMinCeiling(uint256 _newMinCeiling) public virtual {
        uint256 oldMinCeiling = minCeiling;
        minCeiling = _newMinCeiling;
        emit MinCeilingChanged(msg.sender, oldMinCeiling, _newMinCeiling);
    }

    function setMaxCeiling(uint256 _newMaxCeiling) public virtual {
        uint256 oldMaxCeiling = maxCeiling;
        maxCeiling = _newMaxCeiling;
        emit MaxCeilingChanged(msg.sender, oldMaxCeiling, _newMaxCeiling);
    }

    function calcCeiling(uint256 _supply) external view virtual override returns (uint256) {}
}
