# Reentrancy in ERC777

## Description

The Exchange contract allows users to exchange ETH for SSSToken at a calculated rate based on the total amount of SSSToken and ETH in the contract.

## Expected Usage

### Exchange Contract

- Users can call `tokenToEthInput(uint256 tokensSold)` to exchange SSSToken for ETH.
- Users can call `ethToTokenInput()` with value to convert ETH to SSSToken.

### Token Contract

- Follows the standard usage of ERC777.

## Attack

### External Call

The call to `IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);` in the `transfer()` function triggers the user's function before changing balances.

### Cause of Attack

The calculation of the exchange rate is done at the beginning of the transaction, making it vulnerable to multiple `exchange.tokenToEthInput(1*10**18)` calls without state updates.

```solidity
function getInputPrice(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
    require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
    uint256 inputAmountWithFee = inputAmount * 997;
    uint256 numerator = inputAmountWithFee * outputReserve;
    uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
    return numerator / denominator;
}
```

The ETH value calculation remains constant for the same input because the state isn't updated. Therefore, multiple small exchanges can yield a higher total ETH value than a single large exchange.

### Reentrant Target

1. Attacker calls `ethToTokenInput{value: 100 ether}()` to exchange 100 ETH for SSSToken.
2. Attacker calls `tokenToEthInput(1*10**18)` to exchange 1*10**18 SSSToken for ETH.
    - The Exchange calculates the ETH value for 1*10**18 SSSToken.
    - The Exchange calls the external function `tokensToSend()` to notify.
        - During this call, the attacker calls `tokenToEthInput(1*10**18)` again.
            - The Exchange calculates the ETH value for another 1*10**18 SSSToken (without updating the state).
            - This pattern can be repeated multiple times.
            - The Exchange finally updates the state and sends ETH to the attacker.
        - The Exchange updates the state with the previously calculated value.
        - The Exchange sends ETH to the attacker.
    - The Exchange updates the state with the previously calculated value.
    - The Exchange sends ETH to the attacker.

The total ETH returned exceeds the initial amount due to the repeated reentrant calls.

### Mitigation

- Use ReentrancyGuard to prevent reentrant calls.
- Calculate the exchange rate and update the state right before sending the tokens or ETH.

### Resource

- [Exploiting Uniswap: From Reentrancy to Actual Profit](https://blog.openzeppelin.com/exploiting-uniswap-from-reentrancy-to-actual-profit)

By implementing these mitigations, ERC777 reentrancy attacks can be prevented, ensuring secure and accurate token exchanges.
