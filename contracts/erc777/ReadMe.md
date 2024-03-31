# Reentrancy in ERC777
 https://blog.openzeppelin.com/exploiting-uniswap-from-reentrancy-to-actual-profit

## Description

### **erc777modified.sol are modified only erc1820 address. so not related to reentrancy example**

Exchange contract exchange allow user to exchange ETH to SSSToken with calculated rate.

Calculation uses total amount of SSSToken in Exchange contract, total amount of ETH in Exchange contract with corresponding token amount user want to exchange.

## Expected Usage 

### Exchange contract

- User can `tokenToEthInput(uint256 tokensSold)` to exchange SSSToken to ETH.

- User can `ethToTokenInput()` with value to convert ETH to SSSToken.

### Token contract

- Same as defaut usage of ERC777.

## Attack

### External Call 

`IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);`  calls User function, in the `transfer()` function, also before change balances.

### Cause of Attack

They calculate value from at beginnning of transaction state for multiple `exchange.tokenToEthInput(1*10**18)` call.

```solidity
  function getInputPrice(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 997;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        return numerator / denominator;
    }
```

ETHVALUT = SSSTOKENVALUE*997*ETH_BALANCE_IN_EXCHANGE / (SSSTOKEN_IN_EXCHANGE*1000 + SSSTOKENVALUE*997)


it will second and third argument will be constant because we did not update state.
so we can take it as 1 argument( SSSTOKENVALUE ) function. let calc(v)

ETHVALUE1 = calc(10 * v)

ETHVALUE2 = 10 * calc(v)

in this case ETHVALUE2 will bigger since numerator does not change. but denominator will smaller since they adding with constant.

### Reentrant Target

- Attacker call `ethToTokenInput{value: 100 ether}()` to exchange 100 ETH to SSSToken.
- Attacker call `tokenToEthInput(1*10**18)` to exchange 1*10**18 SSSToken to ETH.
    - Exchange calculate Eth value for this 1*10**18 SSSToken.
    - Exchange call external function `tokensToSend()` to notify.
        - Attacker call `tokenToEthInput(1*10**18)` to exchange 1*10**18 SSSToken to ETH.
            - Exchange calculate Eth value for this 1*10**18 SSSToken. (SSSToken and ETH state did not updated.)
            - Exchange call external function `tokensToSend()` to notify.
....................try multiple
            - Exchange do state change with previously calculated value.
            - Exchange send ETH to attacker
        - Exchange do state change with previously calculated value.
        - Exchange send ETH to attacker
    - Exchange do state change with previously calculated value.
    - Exchange send ETH to attacker

Then returned sum would be exceed than initially we have.

### Mitigation 

- Use ReentrancyGuard
- Calculate right before sending

