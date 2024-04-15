// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


contract Vault {
    mapping(address => uint256) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
    /**
     * @notice vulnerable function, it can trigger to call msg.sender function.
     * it can make valult to send amount value of ether repeatly. 
     */
	function withdraw() public {
        uint256 amount = balances[msg.sender];
        msg.sender.call{value: amount}("");
        // also they did not minus from balance like
        // balances[msg.sender] -= amount; so it can not revert.
        balances[msg.sender] = 0 ;
	}
}


