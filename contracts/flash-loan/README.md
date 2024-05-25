# Flush Loan

## Description

Vault enable user to flash loan of ERC20 token.
In this case Vault Manage TKToken

## Expected Usage

- User can `deposit()` to deposit TKToken to the vault.

- User can `withdraw()` to withdraw TKToken which depositted previsously.

- User call `flushLoan(uint256 amount)`, then vault transfer TKToken to the user and it calls `onFlushLoan()` at user contract. it use those flush loan and after this function, Vault check vault balance for check user complete return TKToken.
If user did not returned revert `flushLoan()`.

## Attack

### External Call

`Receiver(msg.sender).onFlushLoan(address(this), amount);`  calls User function, in the `flushLoan()` function, in the vault.

### Cause of Attack

It can Cross function reentrancy.

We can call funcitons in vault in `onFlushLoan()` function.

After `onFlushLoan()` vault just check `token.balanceOf(address(this)) == balanceBefore` which is balance of Vault in TKToken. including all user's deposited tokens.

### Reentrant Target

Attacker can call `deposit()` at Vault and deposit All flushLoaned value.
And it increase `balance` of user in the Vault.
But from TKToken, it just increase vault balance because Attacker deposit to Vault
So `token.balanceOf(address(this))` will restored the satisfy condition.

- Attacker call `flushLoan()` some value from Vault.
  - Vault send Attacker value on TKToken.
  - token.balanceOf( Vault ) will decrease.
  - Vault call attacker external function `onFlushLoan()`.
    - attacker `deposit()` value at Vault.
    - token.balanceOf( Vault ) will restored.

- Attacker can call `withdraw()` that deposited when flushLoaned.

### Mitigation

- Use ReentrancyGuard for Vault
- Do not use token.balanceOf(Vault) but make user to use function for returning loan and track those value by variable.
