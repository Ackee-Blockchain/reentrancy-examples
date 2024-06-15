// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract VulnVault is ReentrancyGuard {

    uint256 private totalTokens;
    uint256 private totalStake;

    mapping (address => uint256) public balances;

    error ReadonlyReentrancy();

    function getCurrentPrice() public view returns (uint256) {
        if(totalTokens == 0 || totalStake == 0) return 10e18;
        return totalTokens * 10e18 / totalStake;
    }

    function deposit() public payable nonReentrant {
        uint256 mintAmount = msg.value * getCurrentPrice() / 10e18;
        totalStake += msg.value;
        balances[msg.sender] += mintAmount;
        totalTokens += mintAmount;
    }

    function withdraw(uint256 burnAmount) public nonReentrant { 
        uint256 sendAmount = burnAmount * 10e18 / getCurrentPrice();
        totalStake -= sendAmount;
        balances[msg.sender] -= burnAmount;
        (bool success, ) = msg.sender.call{value: sendAmount}("");
        require(success, "Failed to send Ether"); 
        totalTokens -= burnAmount;
    }
}