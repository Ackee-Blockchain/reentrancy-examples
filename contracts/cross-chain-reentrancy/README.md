# Cross-Chain Reentrancy Attack

## Description

A cross-chain reentrancy attack exploits the minting process and external calls in cross-chain token transfers, allowing attackers to create duplicate tokens across different chains.

## Expected Usage

Users can use the `mint` and `crossChainTransfer` functions of the `CrossChainWarriors` contract to manage their tokens across multiple chains.

## Attack

### External Call

The attack occurs during the `onERC721Received` function call in the minting process. The attacker triggers `crossChainTransfer` and calls `mint` again, causing `tokenIds` to increment twice.

### Cause of Attack

The root cause is the external call in `_safeMint` combined with incrementing `tokenIds` after the external call, leading to the same token ID being minted on multiple chains.

### Reentrant Target

The `mint` function in the `CrossChainWarriors` contract is targeted, leading to duplicate token IDs across chains.

### Prevention

- **Checks-Effects-Interactions**: This method is the most straightforward and effective solution.

```solidity
function mint(address to) public returns (uint256) {
    require(_mintable, "Minting is disabled");
    uint256 newWarriorId = tokenIds;
    tokenIds++;
    _safeMint(to, newWarriorId);
    return newWarriorId;
}
```

- **Reentrancy Guard**: Use a reentrancyGuard to prevent reentrant calls.

By implementing these prevention, cross-chain reentrancy attacks can be prevented, ensuring the security of the Vault.

### Resources

https://medium.com/@mateocesaroni_11308/cross-chain-re-entrancy-54ec2e924e9c