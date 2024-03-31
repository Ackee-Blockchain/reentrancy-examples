# Reentrancy in ERC1155
https://blocksecteam.medium.com/revest-finance-vulnerabilities-more-than-re-entrancy-1609957b742f
## Description

This vault is very simplified version from original for demonstrate reentrancy.
One user can `create` the lock and that user receive corresponding NFT.
If user pay setted amount, it will unlocked.
By using received nft, user can get corresponding amount of ETH.

## Expected Usage




## Attack

### External Call 


### Cause of Attack

### Reentrant Target


### Mitigation 
