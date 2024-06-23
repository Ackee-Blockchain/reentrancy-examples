# Cross Function Reentrancy

## Description

The Vault accepts ETH deposits from users and allows them to withdraw previously deposited ETH.

## Expected Usage

- Users send ETH to the Vault using the `deposit()` function.
- Users can withdraw their deposited ETH using the `withdraw()` function.

## Attack

### External Call

In the Vault's `withdraw()` function, the call to `msg.sender.call{value: amount}("");` triggers the user's `receive` function.

### Cause of Attack

The Vault updates the user's balance after the external call. When the user's function is called, the balance is in an unexpected state. The attacker receives ETH, but the balance remains unchanged, and after the external call, the balance is set to 0.

### Reentrant Target

The ReentrancyGuard is on `withdraw()` but not on `transfer()`, allowing repeated calls:

1. Attacker deposits 1 ETH.
2. Attacker has a balance of 1 ETH.
3. Attacker calls `withdraw()`.
    - The Vault triggers `receive()` in Attacker1, transferring 1 ETH.
    - During the `receive()` call, Attacker1 transfers 1 ETH of balance to Attacker2 in the Vault.
4. Attacker2 transfers the balance of 1 ETH back to Attacker1.
5. Attacker has a balance of 1 ETH again.
6. Repeat the above steps.

### Prevention

- **ReentrancyGuard**: Apply `nonReentrant` to all functions that users can call to prevent state changes while another function's state change is ongoing.

```solidity
function withdraw() public nonReentrant {
    uint amount = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

- **Checks-Effects-Interactions**: Complete all state changes before making any external calls.

```solidity
function withdraw() public nonReentrant {
    uint amount = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}
```

By implementing these mitigations, cross-function reentrancy attacks can be prevented, ensuring the integrity of the Vault system.
