# Reentrancy in ERC1155

## Description

This vault is very simplified version from original for demonstrate reentrancy.
One user can `create` the lock and that user receive corresponding NFT.
If user pay setted amount, it will unlocked.
By using received nft, user can get corresponding amount of ETH.

## Expected Usage

- User call  `create(uint256 nft_amount, uint256 value)` which generate nft_amount of nfts. and it will able to convert to value of ETH by withdrawing after unlocked.

- User can unlock this nft by paying eth.

- ETH amount corresponding to One nft is `value` / `nft_amount` those are argument of `create()`.

- Benefit of this system is NFT holder can withdraw ETH by this unlocked NFT.

- User can call `create(uint256 nft_amount, uint256 value)` again.
- this nft_amount is not necessary to same as created.
And set new `value` that to be payed additinally.
    - ETH amount corresponding to One nft will (`value_when_crate()`/ `nft_amount_when_create()`) + (`value_when_upate()`/ `nft_amount_when_update()`)

## Attack

### External Call

```IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data)```

for NFT receive, user contract will execute.

### Cause of Attack

if we could update data for same `nft_id`.

they are managing lock `id_to_required_eth[nft_id]`. so they do not deal with the amount of NFT.

and they are managing nft price `nft_price[nft_id]` this indicate price of ONE NFT.

when withdraw called, they use `(the number of nft for this withdraw)` * `nft_price[nft_id]` for eth.

### Reentrant Target

```solidity
 function our_mint(address user, uint256 id, uint256 amount) internal {

        _mint(user, id, amount, "");
        fnftsCreated++;
     
    }
```

they are updating fnftsCreated after complete minting nft.
also they use `getNextId()` this just return value of fnftsCreated. and this value will use as nft id.

so we can mint new nft with small eth value with big number of nft amount and call update in reentrant.

in this update we can set 1 eth and 1 nft. so id_to_required_eth for this nft will 1 eth. this is done in reentrant so nft_id is same as above.

we already have big number of NFT with this nft_id.
In withdraw they calculate eth amount by (the number of NFT)*(nft_price)
so we can withdraw a lot eth.

- Attacker call `create(uint256 nft_amount, uint256 value)` with 1000 nft_amount with 1wei.
    - Vault mint 1000 with nft_id = `getNextId()`. let `k` is nft_id.
    - Vault call attacker function `onERC1155Received()`
        - Attacker call `update(uint256 id, uint256 nft_amount, uint256 value)` with 1 nft_amount with 1 eth.
            - nft_id = `getNextId()` is also `k` same as previously created. since fnftsCreated is not updated.
            - `id_to_required_eth[nft_id]` = 1 eth + 1 wai.
            - `nft_price[nft_id]` = 1 eth.
            - fnftsCreated +=1;
    - fnftsCreated +=1; // too late

- Attacker unlock by 1 eth + 1 wai.
- Attacker withdraw by 1000 nft which nft_id = k.
    - Attacker obtain 1000 eth.

### Mitigation

- make sure which value to be used for nft id then it clear important value update inapropriately.
- update fnftsCreated before minting.

### Resources

https://blocksecteam.medium.com/revest-finance-vulnerabilities-more-than-re-entrancy-1609957b742f