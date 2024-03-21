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


