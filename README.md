## Introduction

This is a covered call smart contract, can be seen as a minimal implementaion of [cally.finance](https://docs.cally.finance/overview/introduction). The seller deposits an NFT into a vault and earns a fee selling the vault. This contract gives the purchaser the right to buy tokens if the contract conditions are met. The contract is considered “covered” because the tokens are deposited into the contract. If the contract conditions are not met then the seller can withdraw his tokens at expiration.

## The example use case

Alice creates an options vault with an NFT. Essentially this is a covered call options contract. Bob buys the option and can exercise the contract if it makes economic sense. If the contract is not exercised Alice can reclaim her tokens and keep the premium payed by Bob.

## Disclaimer

This code is heavily under construction and has not been tested.

Please do not use for production.
