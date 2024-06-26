// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    mapping(address => uint256) private balances;

    function deposit() external payable nonReentrant {
        balances[msg.sender] += msg.value;
    }

    function transfer(address to, uint256 amount) public {
        if (balances[msg.sender] >= amount) {
            balances[to] += amount;
            balances[msg.sender] -= amount;
        }
    }

    function withdraw() public nonReentrant {
        // we can use noReentrant here.
        uint256 amount = balances[msg.sender];
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
        balances[msg.sender] = 0; // did not checked balance. just overwrite to 0.
    }
}
