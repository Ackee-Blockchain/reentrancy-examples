# Reentrancy in ERC721 

## Description

User can mint at most 20 NFT at a time. and The Masks contract manage the information of NFT.
In this contract, the number of all NFT that can generate is 20 by `MAX_NFT_SUPPLY`.

## Expected Usage

- User can `mintNFT()` to mint NFT. User can generate at most 20 NFT per transaction.

## Attack

### External Call 

`IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)`  calls User function, in the `_safeMint()` function, in the Masks contract.

### Cause of Attack

The Masks contract checks the number of minting NFT at beginning of the function.
`totalSupply()` is used `_tokenOwners.length()` and it managed by `EnumerableMap.UintToAddressMap`.
`_tokenOwners.length()` is updated when `  _tokenOwners.set(tokenId, to);` at `_mint()`
So `totalSupply()` is updated for each NFT exact before sending. 

### Reentrant Target



- Attacker call `mintNFT(20)`
- let's say the value of `totalSupply()` is `N`.
- The function `_mint()` update `_tokenOwners`. so now `totalSupply()` is `N+1`.
- The function `_checkOnERC721Received` calls `onERC721Received()` in Attacker Contract.
    - Attacker call `mintNFT(20)`
    - at this moment `totalSupply()` is `N+1`.
    - so we can generate 20 NFT as from totalSupply() is `N+1`.
    - (it will check wether `N+1+20` is less than `MAX_NFT_SUPPLY` or not. but it should check with `N+20+20`).
    - repeat similary above

So we could mintNFT more than 20 in one transaction. also we could Exceed limit of minting in Contract.


### Mitigation 

- Should use one vairable for totalSupply.
- Use Reentrancy Guard.



## principle of least astonishment
https://samczsun.com/the-dangers-of-surprising-code/