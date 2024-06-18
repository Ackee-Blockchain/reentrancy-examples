// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./VulnVault.sol";


contract VictimVault is ReentrancyGuard {
    VulnVault vulnVault;

    mapping (address => uint256) public balances;

    constructor(address vulnVaultAddress) {
        vulnVault = VulnVault(vulnVaultAddress);
    }

    function deposit() public payable nonReentrant {
        uint256 tokenAmount = msg.value * vulnVault.getCurrentPrice() / 10e18;
        balances[msg.sender] += tokenAmount;
    }

    function withdraw(uint256 tokenAmount) public nonReentrant {
        balances[msg.sender] -= tokenAmount;
        uint256 ethAmount = tokenAmount * 10e18 / vulnVault.getCurrentPrice();
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "Failed to send Ether"); 
    }
}
