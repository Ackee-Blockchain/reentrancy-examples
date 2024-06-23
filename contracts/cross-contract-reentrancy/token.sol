// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CCRToken is ERC20, Ownable {
    // (manager i.e. victim) is trusted, so only they can mint and burn token
    constructor(address manager) ERC20("CCRToken", "CCRT") Ownable(manager) {}

    // only manager mint token
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    // burn token

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
