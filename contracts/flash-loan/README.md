# Flash Loan

## Description

Vault enable user to flash loan of ERC20 token.
In this case Vault Manage TKToken

## Expected Usage

- User can `deposit()` to deposit TKToken to the vault.

- User can `withdraw()` to withdraw TKToken which depositted previsously.

- User call `flashLoan(uint256 amount)`, then vault transfer TKToken to the user and it calls `onFlashLoan()` at user contract. it use those flash loan and after this function, Vault check vault balance for check user complete return TKToken.
If user did not returned revert `flashLoan()`.

## Attack

### External Call

`Receiver(msg.sender).onFlashLoan(address(this), amount);`  calls User function, in the `flashLoan()` function, in the vault.

### Cause of Attack

It can Cross function reentrancy.

We can call funcitons in vault in `onFlashLoan()` function.

After `onFlashLoan()` vault just check `token.balanceOf(address(this)) == balanceBefore` which is balance of Vault in TKToken. including all user's deposited tokens.

### Reentrant Target

Attacker can call `deposit()` at Vault and deposit All flashLoaned value.
And it increase `balance` of user in the Vault.
But from TKToken, it just increase vault balance because Attacker deposit to Vault
So `token.balanceOf(address(this))` will restored the satisfy condition.

- Attacker call `flashLoan()` some value from Vault.
  - Vault send Attacker value on TKToken.
  - token.balanceOf( Vault ) will decrease.
  - Vault call attacker external function `onFlashLoan()`.
    - attacker `deposit()` value at Vault.
    - token.balanceOf( Vault ) will restored.

- Attacker can call `withdraw()` that deposited when flashLoaned.

### Mitigation

- Use ReentrancyGuard for Vault
- Do not use token.balanceOf(Vault) but make user to use function for returning loan and track those value by variable.
