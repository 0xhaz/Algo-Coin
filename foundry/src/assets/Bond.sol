// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {Operator} from "../access/Operator.sol";

/**
 * @title Basis Bond ERC-20
 * @author 0xhaz
 * @notice Basis Bonds are minted and redeemed to incentivize changes in the Basis Cash supply.
 * @notice Bonds are always on sale to Basis Cash holders, although purchases are expected to be made at a price below 1 Basis Cash.
 * @notice Holders are able to exchange their bonds to Basis Cash tokens in the Basis Cash Treasury.
 * @notice They are able to convert 1 Basis Bond to 1 Basis Cash, earning them a premium on their previous bond purchase price.
 */
contract Bond is ERC20Burnable, Operator {
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() ERC20("BAB", "BAB") {
        // Mints 1 Basis Cash to contract creator for initial Uniswap oracle deployment
        // Will be burned after oracle deployment
        _mint(_msgSender(), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Operator mints basis bonds to a recipient
     * @param recipient_ The address of the recipient
     * @param amount_ The amount of basis bonds to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    /*//////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Operator burns basis bonds from the caller
     * @param amount_ The amount of basis bonds to burn
     */
    function burn(uint256 amount_) public override onlyOperator {
        super.burn(amount_);
    }

    /**
     * @notice Operator burns basis bonds from a recipient
     * @param account The address of the recipient
     * @param amount The amount of basis bonds to burn from
     */
    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }
}
