# Reentrancy in ERC1155

## Description

The Vault contract allows users to create ETH lock NFTs, distribute them, pay ETH to unlock them, and withdraw ETH by burning the NFTs. This contract demonstrates the potential for reentrancy vulnerabilities.

## Expected Usage

- Users call `create` to create ETH lock NFTs.
- Users distribute these NFTs to others.
- Users call `payEth` to unlock the NFTs.
- NFT holders call `withdraw` to burn the NFTs and receive corresponding ETH.

## Attack

### External Call

The external call to `IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data)` in the `mint` function of the Vault contract triggers the user's function.

### Cause of Attack

The Vault updates `fnftsCreated` after the external call, allowing an attacker to manipulate NFT data for the same `nft_id`.

### Reentrant Target

1. Attacker calls `create(1000, 1 wei)` to mint 1000 NFTs with `nft_id = k`.
2. During the `onERC1155Received()` callback:
    - Attacker calls `create(1, 1 ETH)` to mint 1 NFT with `nft_id = k`.
    - `id_to_required_eth[k]` is set to 1 ETH.
    - `nft_price[k]` is set to 1 ETH.
    - `fnftsCreated` is incremented twice after the reentrancy.
3. Attacker unlocks by paying 1 ETH.
4. Attacker withdraws 1001 NFTs with `nft_id = k` and receives 1001 ETH.

### Prevention

- **Check-Effects-Interacts**: Apply the checks-effects-interactions pattern to ensure state changes before external calls.

```solidity
function mint(address user, uint256 id, uint256 amount) internal {
    fnftsCreated++;
    _mint(user, id, amount, "");   
}
```

- **ReentrancyGuard**: Use ReentrancyGuard to prevent reentrant calls.

By implementing them, reentrancy attacks in ERC1155 contracts can be prevented, ensuring secure NFT operations.

### Resources

- [Revest Finance Vulnerabilities: More Than Re-Entrancy](https://blocksecteam.medium.com/revest-finance-vulnerabilities-more-than-re-entrancy-1609957b742f)
