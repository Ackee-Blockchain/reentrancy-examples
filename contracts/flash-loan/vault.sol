// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


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
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }

    function flashLoan(uint256 amount) public {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= amount, "Insufficient funds in contract");

        require(token.transfer(msg.sender, amount), "Transfer failed");

        Receiver(msg.sender).onFlashLoan(address(this), amount);

        require(token.balanceOf(address(this)) == balanceBefore, "Loan not paid back");
    }
}

interface Receiver {
    function onFlashLoan(address contractAddress, uint256 amount) external;
}