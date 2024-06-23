# Reentrancy in ERC721

## Description

Users can mint up to 20 NFTs at a time. The Masks contract manages the information of these NFTs, with a total supply limit of 20 NFTs as defined by `MAX_NFT_SUPPLY`.

## Expected Usage

- Users can call `mintNFT()` to mint NFTs, with a maximum of 20 NFTs per transaction.

## Attack

### External Call

The call to `IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)` in the `_safeMint()` function triggers the user's function within the Masks contract.

### Cause of Attack

The Masks contract checks the number of minting NFTs at the beginning of the function. The `totalSupply()` uses `_tokenOwners.length()` managed by `EnumerableMap.UintToAddressMap`. `_tokenOwners.length()` is updated when `tokenOwners.set(tokenId, to);` is called in `_mint()`. Thus, `totalSupply()` is updated for each NFT just before sending.

### Reentrant Target

1. The attacker calls `mintNFT(20)`.
2. Suppose `totalSupply()` is `N`.
3. The `_mint()` function updates `_tokenOwners`, making `totalSupply()` `N+1`.
4. The `_checkOnERC721Received` function calls `onERC721Received()` in the attacker contract.
    - The attacker calls `mintNFT(20)` again.
    - At this moment, `totalSupply()` is `N+1`.
    - This allows minting 20 more NFTs since the check uses `N+1+20`, but it should check `N+20+20`.
    - Repeat similarly to mint more than 20 NFTs in one transaction, exceeding the contract's minting limit.

### Mitigation

- **ReentrancyGuard**: Implement a ReentrancyGuard to prevent reentrant calls.
- Use a single variable to track `totalSupply`.

### Resource

- [The Dangers of Surprising Code](https://samczsun.com/the-dangers-of-surprising-code/)

By adopting these mitigations, reentrancy attacks in ERC721 contracts can be prevented, ensuring the integrity of the minting process and adherence to supply limits.
