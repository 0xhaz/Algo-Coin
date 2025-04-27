## Algorithmic Stablecoin

**This is an enhancement version of Basis Cash with added features with the latest integrations with Chainlink and OpenZeppelin**

Basis Cash is an open-source, permissionless algorithmic stablecoin

The Basis Cash protocol aims to revive the original vision of [basis.io](https://basis.io)

Adding some ideas for learning purposes and not to be use on production yet!

## Tokens

### BAC - Basis Cash

Basis Cash tokens are designed to be used as a medium of exchange. The built-in stability mechanism expands and contracts their supply, maintaining their peg to the MakerDAO **Multi-Collateral Dai** token (pegged to 1 USD)

### BAB - Basis Bonds

Basis Bonds are minted and redeemed to incentivize changes in the Basis Cash supply. Bonds are always on sale to Basis Cash holders, although purchases are expected to be made at a price below 1 Basis Cash. At any given time, holders are able to exchange their bonds to Basis Cash tokens in the Basis Cash Treasury. Upon redemption, they are able to convet 1 Basis Bond to 1 Basis Cash, eaning them a premium on their previous bond purchases.

Contrary to Basis Bonds of basis.io, bonds in Basis Cash do not have expiration dates. All holders are able to convert their bonds to Basis Cash tokens, as long as the Treasury has a positive BAC balance.

### BAS - Basis Shares

Basis Shares loosely represent the value of the Basis Cash network. Increased demand for Basis Cash results in new Basis Cash tokens to be minted and distributed to Basis Share holders, provided that the Treasury is sufficiently full

Holders of Basis Share tokens can claim a pro-rata share of Basis Cash tokens accumulated to the Boardroom contract

## Cash Pools

### Treasury

The Basis Cash Treasury exists to enable bond-to-cash redemptions. Bonds redeemed via the Treasury automatically returns the user and equal number of Basis Cash, provided that: 1) the oracle price of Basis Cash is above 1 DAI, and 2) the Treasury contract has a positive balance of Basis Cash.

Disallowing redemptions when the Basis Cash price is below 1 DAI prevents bond holders from prematurely cutting their losses and creating unnecessary downward pressure on the price of BAC

In addition, as the price of BAC is likely to experience significant volatility during its phase of initial distribution (first 5 days), the Treasury is scheduled to start after initial distribution concludes (starting from day 6 of launch). This is to grant the BAC market enough to stabilize, after which the protocol makes effective use of the stabilization mechanism to prevent further deviations in price

### Boardroom

The Boardroom allows Basis Share holders to claim excess Basis Cash minted by the protocol. Holders of Basis Shares can stake their Shares to the Boardroom contract, which by doing so, they can claim a pro-rata share of Basis Cash tokens assigned to the Boardroom.
