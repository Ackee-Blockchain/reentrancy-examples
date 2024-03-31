// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// A simplified ERC20 interface
contract Token is ERC20 {
    constructor(uint256 initial_value) ERC20("Token", "TK"){
        _mint(msg.sender, initial_value);
    }
}
