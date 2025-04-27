// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Operator} from "../access/Operator.sol";

/**
 * @title Basis Cash
 * @author 0xhaz
 * @notice This tokens are designed to be used as a medium of exchange. The built in stability mechanism expands and contracts their supply
 * @notice maintaining their peg to the MakerDAO Multi-Collateral DAI token
 */
contract Cash is ERC20Burnable, Operator {
    constructor() ERC20("BAC", "BAC") {
        // Mints 1 Basis Cash to contract creator for initial Uniswap oracle deployment
        // Will be burned after oracle deployment
        _mint(_msgSender(), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Operator mints basis cash to a recipient
     * @param recipient_ The address of the recipient
     * @param amount_ The amount of basis cash to mint to
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
     * @notice Operator burns basis cash from the caller
     * @param amount_ The amount of basis cash to burn
     */
    function burn(uint256 amount_) public override onlyOperator {
        super.burn(amount_);
    }

    /**
     * @notice Operator burns basis cash from a recipient
     * @param account The address of the recipient
     * @param amount The amount of basis cash to burn from
     */
    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }
}
