// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    mapping (address => uint) private balances;

    function deposit() external payable nonReentrant {
        balances[msg.sender] += msg.value;
    }

    function transfer(address to, uint amount) public {
        if (balances[msg.sender] >= amount) {
            balances[to] += amount;
            balances[msg.sender] -= amount;
        }
    }

    function withdraw() public nonReentrant { // we can use noReentrant here.
        uint amount = balances[msg.sender];
        msg.sender.call{value: amount}("");
        balances[msg.sender] = 0; // did not checked balance. just overwrite to 0.
    }
}

