// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Operator} from "../access/Operator.sol";

contract ShareV2 is ERC20Burnable, Operator {
    constructor() ERC20("BASv2", "BASv2") {}

    /*//////////////////////////////////////////////////////////////
                                    PUBLIC  
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Operator mints basis shares to a recipient
     * @param recipient_ The address of the recipient
     * @param amount_ The amount of basis shares to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter >= balanceBefore;
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDES
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Operator burns basis shares from the caller
     * @param amount_ The amount of basis shares to burn
     */
    function burn(uint256 amount_) public override onlyOperator {
        super.burn(amount_);
    }

    /**
     * @notice Operator burns basis shares from a recipient
     * @param account The address of the recipient
     * @param amount The amount of basis shares to burn from
     */
    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }
}
