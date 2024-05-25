# Single Function Reentrancy

## Description

Vault accept user ETH and user can withdraw previously deposited ETH.

## Expected Usage

- User send ETH to Vault with `deposit()` function.

- User can do `withdraw()` then get ETH from deposited Vault same amount as deposit.

## Attack

### External Call

In the Vault, in the `withdraw()` function.
They do `msg.sender.call{value: amount}("");` which trigger user's `receive` function.

### Cause of Attack

It update balance after the external call.
So when the user function is called, balance is unexpected state.

Attacher already receive ETH but balance did not changed same as before called `withdraw()`.
and after external call, just setting balalnce to 0.

### Reentrant Target

We can call `withdraw()` again and again.

- Attacker deposit 1 eth.
- So Attacker have balance of 1 eth.
- Attacker withdraw()
  - Vault call receive() in Attacker at the same time Attacker receive 1 eth.
  - Attacker can call withdraw() still balance is 1 eth.
- repeat above.

### Mitigation

- Minus balance same amount as sent ETH by external call.
- Complete changing state before external call.
