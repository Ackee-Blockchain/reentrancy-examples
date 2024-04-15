# Cross Function Reentrancy

## Description
Vault accept user ETH and user can withdraw previously deposited ETH.

## Expected Usage

- User send ETH to Vault with ` deposit()` function.
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

There is ReentrancyGuard on `withdraw()` but not `transfer()`.


### Reentrant Target

We can call `withdraw()` again and again.

- Attacker deposit 1 eth.
- So Attacker have balance of 1 eth.
- Attacker1 withdraw()
    - Vault call receive() in Attacker1 at the same time Attacker1 receive 1 eth.
    - Attacker1 can transfer() 1 eth of balance from Attacker1 to Attacker2 in vault.
- Attacker2 transfer balance of 1 eth to Attacker1.
- So Attacker have balance of 1 eth.
- repeat above.


### Mitigation 

- Set ReentrancyGuard also on `transfer()`.
- Minus balance same amount as sent ETH by external call.
- Complete changing state before external call.
