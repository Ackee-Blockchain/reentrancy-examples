# Cross Contract Reentrancy

## Description

There is an ETH token and a CCRToken. The Vault manages CCRToken, allowing it to mint and burn tokens, making it a trusted entity for CCRToken.

## Expected Usage

- Users send ETH to the Vault using the `deposit()` function, which mints CCRTokens equivalent to the deposited ETH for the user.
- Users can call `withdraw()` to exchange their CCRTokens for ETH.

## Attack

### External Call

In the Vault's `withdraw()` function, the call to `msg.sender.call{value: balance}("");` triggers the user's `receive` function.

### Cause of Attack

The Vault updates the CCRToken balance after the external call. When the user's function is called, the CCRToken is in an unexpected state. The attacker receives ETH, but the CCRToken balance remains unchanged. The `burnUser()` function then burns the CCRTokens from the current `msg.sender` value.

### Reentrant Target

Despite having a ReentrancyGuard in the Vault, the attacker can still call CCRToken functions:

1. Attacker1 deposits 1 ETH, receiving CCRTokens equivalent to 1 ETH.
2. Attacker1 calls `withdraw()`.
    - The Vault triggers `receive()` in Attacker1, transferring 1 ETH.
    - Attacker1 calls `transfer()` in CCRToken, transferring CCRTokens to Attacker2.
3. Attacker2 transfers CCRTokens back to Attacker1.
4. Attacker1 again has CCRTokens equivalent to 1 ETH.
5. Repeat the above steps.

### Mitigation

- Burn the same amount of CCRTokens as the sent ETH.
- Complete state changes before making external calls.

By implementing these mitigations, cross-contract reentrancy attacks can be prevented, ensuring the integrity of the Vault and CCRToken system.