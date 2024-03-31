// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// A mock contract to demonstrate reentrancy
contract Vault {
    IERC20 public token;

    // Mapping of address to balance
    mapping(address => uint256) public balances;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function balanceOf(address account)public view returns(uint256){
        return balances[account];
    }

    // Deposit tokens into the contract
    function deposit(uint256 amount) public {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance"); // Checks
        balances[msg.sender] -= amount; // Effects
        require(token.transfer(msg.sender, amount), "Transfer failed"); // Interactions
    }

    // Execute a flash loan
    function flushLoan(uint256 amount) public {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient funds in contract");

        // Transfer tokens to the receiver (caller)
        require(token.transfer(msg.sender, amount), "Transfer failed");

        // Callback to the receiver to execute custom logic
        Receiver(msg.sender).onFlushLoan(address(this), amount);

        // Check balance after the callback to ensure tokens are returned
        require(token.balanceOf(address(this)) == balanceBefore, "Loan not paid back");
    }
}

// A mock receiver contract interface to simulate the callback during the flash loan
interface Receiver {
    function onFlushLoan(address contractAddress, uint256 amount) external;
}