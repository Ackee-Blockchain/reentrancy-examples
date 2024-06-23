# Reentrancy examples
A repository with examples of reentrancy vulnerabilities and their exploitations in [Wake framework](https://ackee.xyz/wake/docs/latest/).

The description for each reentrancy is in the corresponding directory.

* [Cross-chain reentrancy](contracts/cross-chain-reentrancy)
* [Cross-contract reentrancy](contracts/cross-contract-reentrancy)
* [Cross-function reentrancy](contracts/cross-function-reentrancy)
* [ERC-1155 reentrancy](contracts/erc1155)
* [ERC-721 reentrancy](contracts/erc721)
* [ERC-777 reentrancy](contracts/erc777)
* [Flash loan reentrancy](contracts/flash-loan)
* [Read-only reentrancy](contracts/read-only-reentrancy)
* [Single-function reentrancy](contracts/single-function-reentrancy)

Exploits can be found in `tests` folder.

![horizontal splitter](https://github.com/Ackee-Blockchain/wake-detect-action/assets/56036748/ec488c85-2f7f-4433-ae58-3d50698a47de)

## Setup
```shell
npm ci
wake up
```

## Run specific exploit
```shell
wake test tests/test_1_single_function_reentrancy.py
```
