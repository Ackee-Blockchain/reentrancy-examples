// SPDX-License-Identifier: None
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Vault is ERC1155 {

    mapping(uint256 => uint256) public idToRequiredEth;
    mapping(uint256 => bool) public payed;
    mapping(uint256 => uint256) public nftPrice;

    uint public fnftsCreated = 0;

    function getNftPrice(uint256 id) public view returns(uint256){
        return nftPrice[id];
    }

    function getRquire(uint256 id)public view returns(uint256){
        return idToRequiredEth[id];
    }

    function getNextId() public view returns(uint256){
        return fnftsCreated;
    }

    constructor() ERC1155("") payable {
  
    }
    

    function create(uint256 nftAmount, uint256 value) public returns (uint256){
        // uint256 id = getCurrId();
        uint256 id = getNextId();
        idToRequiredEth[id] = value * nftAmount; // this is kind of lock
        nftPrice[id] = value;
        our_mint(msg.sender, id, nftAmount);

        return id;
    }
    
    // user want to update 
    function update(uint256 id, uint256 nftAmount, uint256 value) public returns(uint256){
        uint256 nextId = getNextId();
        

        _burn(msg.sender, id, nftAmount);

        require(idToRequiredEth[id] > 0, "require is not zero");
        

        idToRequiredEth[nextId] =  nftAmount * (value + nftPrice[id]);
        nftPrice[nextId] = nftPrice[id] + value;

        our_mint(msg.sender, nextId, nftAmount);
        
        return nextId;
    }


    function pay_eth(uint256 id ) public payable {
        require(payed[id] == false, "already payed");

        require(msg.value == idToRequiredEth[id], "incorrect eth amount");
        payed[id] = true;
    }


    function withdraw (uint256 id) public {
        require(payed[id] == true, "did not unlocked, (completed pay)");

        uint256 nftAmount = balanceOf(msg.sender, id);

        _burn(msg.sender, id, nftAmount);

        // payable(msg.sender).call{value: nft_price[id] * nft_amount }("");
        payable(msg.sender).transfer(nftPrice[id] * nftAmount);
    }

    // in oiginal source code they have manager and token contract.
    // so from this (manager) contract, it looks just calling original erc1155 token mint function.
    // but in token contract, they have data modification.
    
    // - Cross contract  (we removed this feature for the example)
    // - Cross function  reentrancy

    function our_mint(address user, uint256 id, uint256 amount) internal {
        _mint(user, id, amount, "");
        fnftsCreated++;
    }
}