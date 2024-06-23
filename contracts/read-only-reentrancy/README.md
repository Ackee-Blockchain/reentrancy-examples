# Read Only Reentrancy

## Description

Read Only Reentrancy attack exploits the view function and reentrancy feature, allowing an attacker to manipulate token prices by exploiting discrepancies in the `getCurrentPrice` function during state changes.

## Expected Usage

Users can use the `deposit` and `withdraw` functions of both the `VulnVault` and `VictimVault` contracts.

## Attack

### External Call

The attack occurs when the `withdraw` function of `VulnVault` is called, triggering the external call where `getCurrentPrice` is manipulated.

### Cause of Attack

The attack arises because `getCurrentPrice` returns different values when called in the middle of state changes, causing the price to be inaccurately high.

### Reentrant Target

The `getCurrentPrice` function in `VulnVault` is exploited during the `withdraw` process, affecting the dependent `VictimVault` contract.

### Mitigation

1. **ReentrancyGuard**: Implement a reentrancy guard within the `getCurrentPrice` function to prevent reentrant calls.

```solidity
function getCurrentPrice() public view returns (uint256) {
    if(_reentrancyGuardEntered()){
        revert ReadonlyReentrancy();
    }
    if(totalTokens == 0 || totalStake == 0) return 10e18;
    return totalTokens * 10e18 / totalStake;
}
```

2. **Checks-Effects-Interactions Pattern**: Ensure all state changes occur before any external calls.

```solidity
function withdraw(uint256 burnAmount) public nonReentrant { 
    uint256 sendAmount = burnAmount * 10e18 / getCurrentPrice();
    totalStake -= sendAmount;
    balances[msg.sender] -= burnAmount;
    totalTokens -= burnAmount;
    payable(msg.sender).call{value: sendAmount}("");
}
```

This pattern ensures the `getCurrentPrice` function returns a trusted value, even if recursively called.
