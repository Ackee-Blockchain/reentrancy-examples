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

### Prevention

- **Checks-Effects-Interactions**: Complete state changes before making any external calls to prevent reentrancy attacks.

```solidity
CCRToken public customToken;

function burnUser() internal {
    customToken.burn(msg.sender, customToken.balanceOf(msg.sender));
}

function withdraw() external nonReentrant {
    uint256 balance = customToken.balanceOf(msg.sender);
    require(balance > 0, "Insufficient balance");
    burnUser();
    (bool success, ) = msg.sender.call{value: balance}(""); 
    require(success, "Failed to send Ether"); 
}
```

- **ReentrancyGuard**: A simple reentrancy guard alone cannot prevent this attack.

- **Check the value before writing after the external call**: Ensure the state does not change unexpectedly due to an external call by using the previously stored balance value.

```solidity
CCRToken public customToken;

function burnUser(uint256 balance) internal {
    customToken.burn(msg.sender, balance);
}

function withdraw() external nonReentrant {
    uint256 balance = customToken.balanceOf(msg.sender);
    require(balance > 0, "Insufficient balance");
    (bool success, ) = msg.sender.call{value: balance}(""); 
    require(success, "Failed to send Ether"); 
    burnUser(balance);
}
```

By implementing these mitigations, cross-contract reentrancy attacks can be prevented, ensuring the integrity of the Vault system.
