# Single Function Reentrancy

## Description

The Vault contract accepts ETH deposits from users and allows them to withdraw previously deposited ETH.

## Expected Usage

- Users send ETH to the Vault using the `deposit()` function.
- Users can call `withdraw()` to withdraw the same amount of ETH they deposited.

## Attack

### External Call

In the Vault's `withdraw()` function, the call to `msg.sender.call{value: amount}("");` triggers the user's `receive` function.

### Cause of Attack

The Vault updates the user's balance after the external call, which means the balance is in an unexpected state when the user's function is called. The attacker receives ETH, but their balance remains unchanged, allowing repeated `withdraw()` calls.

### Reentrant Target

The attacker can call `withdraw()` repeatedly:

1. Attacker deposits 1 ETH.
2. The attacker has a balance of 1 ETH.
3. The attacker calls `withdraw()`.
   - The Vault calls `receive()` in the attacker contract, transferring 1 ETH.
   - The attacker can call `withdraw()` again while their balance is still 1 ETH.
4. Repeat the above steps.

### Mitigation

- Deduct the balance by the amount of ETH sent before the external call.
- Complete all state changes before making the external call.

By implementing these mitigations, single function reentrancy attacks can be prevented, ensuring the security of the Vault.
