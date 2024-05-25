// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VulnPool is ReentrancyGuard {

    uint256 private totalTokens;
    uint256 private totalStake;

    mapping (address => uint256) public balances;

    error ReadonlyReentrancy();

    function getCurrentPrice() public view returns (uint256) { // total token is not updated and it return high value
        if(_reentrancyGuardEntered()){
            revert ReadonlyReentrancy();
        }
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
        payable(msg.sender).call{value: sendAmount}("");
        totalTokens -= burnAmount;
    }
}

contract VictimPool is ReentrancyGuard {

    VulnPool vulnPool;

    mapping (address => uint256) public balances;

    constructor(address vulnPoolAddress) {
        vulnPool = VulnPool(vulnPoolAddress);
    }

    function deposit() public payable nonReentrant {
        uint256 tokenAmount = msg.value * vulnPool.getCurrentPrice() / 10e18;
        balances[msg.sender] += tokenAmount;
    }


    function withdraw(uint256 tokenAmount) public nonReentrant {
        balances[msg.sender] -= tokenAmount;
        uint256 ethAmount = tokenAmount * 10e18 / vulnPool.getCurrentPrice();
        msg.sender.call{value: ethAmount}("");
    }
    
}

