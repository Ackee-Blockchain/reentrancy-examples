// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./erc777modified.sol";

contract MyERC777Token is ERC777 {
    constructor(
        uint256 initialSupply,
        address[] memory defaultOperators,
        address registry
    ) ERC777("SSSToken", "SSST", defaultOperators, registry){
        _mint(msg.sender, initialSupply, "", "");
    }
}