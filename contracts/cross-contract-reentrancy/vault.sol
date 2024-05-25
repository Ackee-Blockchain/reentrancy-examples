// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./token.sol";


contract Vault is ReentrancyGuard, Ownable {
    CCRToken public customToken;

    constructor() Ownable(msg.sender) {}

    function setToken(address _customToken) external onlyOwner {
        customToken = CCRToken(_customToken);
    }   

    function deposit() external payable nonReentrant {
        customToken.mint(msg.sender, msg.value); //eth to CCRT
    }

    function burnUser() internal {
        customToken.burn(msg.sender, customToken.balanceOf(msg.sender));
    }

    /**
     * @notice Vulnerable function. similary cross function reentrancy but it harder to find.
     * it uses other contract and it has different feature from just variables.
     */
    function  withdraw() external nonReentrant {
        uint256 balance = customToken.balanceOf(msg.sender);
        require(balance > 0, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: balance}(""); 
        // attacker call transfer ccrt balance to another account in the callback function.
        require(success, "Failed to send Ether"); 

        burnUser();
    }
}




