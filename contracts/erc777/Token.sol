// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "node_modules/openzeppelin-solidity-3.4.0/token/ERC777/ERC777.sol";

contract MyERC777Token is ERC777 {
    constructor(uint256 initialSupply, address[] memory defaultOperators)
        ERC777("SSSToken", "SSST", defaultOperators)
    {
        _mint(msg.sender, initialSupply, "", "");
    }
}
