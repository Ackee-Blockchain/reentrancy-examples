# Complete Reentrancy Examples

A repository with examples of reentrancy vulnerabilities and their exploitations in [Wake framework](https://ackee.xyz/wake/docs/latest/).

There are articles for each example.

## Reentrancy Examples by Type

| Type | Documentation | Example | Test |
|------|---------|---------|------|
| Single-function reentrancy | [Article](https://ackee.xyz/blog/single-function-reentrancy-attack/) | [Example](contracts/single-function-reentrancy) | [Test](tests/test_1_single_function_reentrancy.py) |
| Cross-function reentrancy | [Article](https://ackee.xyz/blog/cross-function-reentrancy-attack/) | [Example](contracts/cross-function-reentrancy) | [Test](tests/test_2_cross_function_reentrancy.py) |
| Cross-chain reentrancy | [Article](https://ackee.xyz/blog/cross-chain-reentrancy-attack/) | [Example](contracts/cross-chain-reentrancy) | [Test](tests/test_9_cross_chain_reentrancy.py) |
| Cross-contract reentrancy | [Article](https://ackee.xyz/blog/cross-contract-reentrancy-attack/) | [Example](contracts/cross-contract-reentrancy) | [Test](tests/test_3_cross_contract_reentrancy.py) |
| Read-only reentrancy | [Article](https://ackee.xyz/blog/read-only-reentrancy-attack/) | [Example](contracts/read-only-reentrancy) | [Test](tests/test_8_read_only_reentrancy.py) |

## Reentrancy Examples in Protocols

| Type | Documentation | Example | Test |
|------|---------|---------|------|
| Flash loan reentrancy | [Article](https://ackee.xyz/blog/flash-loan-reentrancy-attack/) | [Example](contracts/flash-loan) | [Test](tests/test_4_flash_loan.py) |
| ERC-721 reentrancy | [Description](contracts/erc721/README.md) | [Example](contracts/erc721) | [Test](tests/test_5_erc721.py) |
| ERC-777 reentrancy | [Article](https://ackee.xyz/blog/reentrancy-attack-in-erc-777/) | [Example](contracts/erc777) | [Test](tests/test_6_erc777.py) |
| ERC-1155 reentrancy | [Description](contracts/erc1155/README.md) | [Example](contracts/erc1155) | [Test](tests/test_7_erc1155.py) |


Exploits can be found in the `tests` folder.

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
