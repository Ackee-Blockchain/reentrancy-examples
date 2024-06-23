# Flash Loan

## Description

The Vault enables users to take flash loans of ERC20 tokens, specifically managing TKToken.

## Expected Usage

- Users can `deposit()` to deposit TKToken into the vault.
- Users can `withdraw()` to withdraw previously deposited TKToken.
- Users can call `flashLoan(uint256 amount)`, which transfers TKToken to the user and calls `onFlashLoan()` in the user's contract. After this function, the Vault checks its balance to ensure the user has returned the TKToken. If the user has not returned the tokens, `flashLoan()` reverts.

## Attack

### External Call

The `Receiver(msg.sender).onFlashLoan(address(this), amount);` call in the `flashLoan()` function triggers the user's function.

### Cause of Attack

The attack exploits cross-function reentrancy. During the `onFlashLoan()` function, the attacker can call other functions in the Vault.

After `onFlashLoan()`, the Vault only checks `token.balanceOf(address(this)) == balanceBefore`, which includes all users' deposited tokens.

### Reentrant Target

The attacker can call `deposit()` in the Vault to deposit the flash loaned amount, increasing the user's balance in the Vault. However, from the TKToken perspective, it just increases the Vault's balance, restoring `token.balanceOf(address(this))` to satisfy the condition.

1. Attacker calls `flashLoan()` to borrow some amount from the Vault.
   - The Vault sends the flash loan amount in TKToken to the attacker.
   - `token.balanceOf(Vault)` decreases.
   - The Vault calls the attacker's external function `onFlashLoan()`.
     - The attacker deposits the amount back into the Vault.
     - `token.balanceOf(Vault)` is restored.
2. The attacker can then call `withdraw()` to withdraw the deposited amount from the flash loan.

### Prevention

- It is necessary to follow the specification of ERC-3156 and best practice.

- Do not rely on `token.balanceOf(Vault)`. Instead, require users to use a specific function to return the loan and track the returned amount with a separate variable.

- **ReentrancyGuard**: Use ReentrancyGuard in the Vault.

By implementing them, reentrancy attacks on the flash loan can be prevented, ensuring the security of the Vault.
