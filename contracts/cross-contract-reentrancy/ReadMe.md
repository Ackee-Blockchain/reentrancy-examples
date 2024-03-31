# Cross Contract Reentrancy

## Description

There is ETH token and CCRToken. 
Vault manage CCRToken. so vault is trusted from CCRToken so vault can mint and burn token.

## Expected Usage

- User send ETH to Vault with ` deposit()` function. Vault run mint at CCRToken as msg.sender token.

- User can do `withdraw()` then get ETH from deposited CCRToken.

## Attack

### External Call 

In the Vault, in the `withdraw()` function. They do `msg.sender.call{value: balance}("");` which trigger user's `receive` function.


### Cause of Attack

It update CCRToken balance after the external call. 
So when the user function is called, CCRToken is unexpected state.
Attacker already receive ETH but CCRToken did not changed same as before called `withdraw()`.
and `burnUser()` function burn CCRToken from currently msg.sender value.

### Reentrant Target

There is ReentrancyGuard in the vault. but we can call CCRToken function.

- Attacker1 deposit 1 eth.
- So Attacker1 have CCRToken which equal value to 1 eth.
- Attacker1 withdraw()
    - Vault call receive() in Attacker1 at the same time Attacker receive 1 eth.
    - Attacker1 call transfer() in CCRToken then transfer CCRToken to attacker2.
- Attacker2 transfer() CCRToken to Attacker1.
- So Attacker1 have CCRToken which equal value to 1 eth.
- repeat above.

### Mitigation 

- Burn same amount that sent ETH.
- Complete changing state before external call.
