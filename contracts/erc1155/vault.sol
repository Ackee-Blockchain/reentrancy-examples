// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Vault is ERC1155 {

    mapping(uint256 => uint256) public id_to_required_eth;
    mapping(uint256 => bool) public payed;
    mapping(uint256 => uint256) public nft_price;

    uint public fnftsCreated = 0;

    function getNftPrice(uint256 id) public view returns(uint256){
        return nft_price[id];
    }

    function getRquire(uint256 id)public view returns(uint256){
        return id_to_required_eth[id];
    }

    function getNextId() public view returns(uint256){
        return fnftsCreated;
    }

    constructor() ERC1155("") payable {
  
    }
    

    function create(uint256 nft_amount, uint256 value) public returns (uint256){
        // uint256 id = getCurrId();
        uint256 id = getNextId();
        id_to_required_eth[id] = value * nft_amount; // this is kind of lock
        nft_price[id] = value;
        our_mint(msg.sender, id, nft_amount);

        return id;
    }
    
    // user want to update 
    function update(uint256 id, uint256 nft_amount, uint256 value) public returns(uint256){
        uint256 next_id = getNextId();
        

        _burn(msg.sender, id, nft_amount);

        require(id_to_required_eth[id] > 0, "require is not zero");
        // uint256 prev_value = id_to_required_eth[id];
        

        id_to_required_eth[next_id] =  nft_amount * (value + nft_price[id]);
        nft_price[next_id] = nft_price[id] + value;

    
        our_mint(msg.sender, next_id, nft_amount);
        
       
        return next_id;
    }


    function pay_eth(uint256 id ) public payable {
        require(payed[id] == false, "already payed");

        require(msg.value == id_to_required_eth[id], "incorrect eth amount");
        payed[id] = true;
    }


    function withdraw (uint256 id) public {
        require(payed[id] == true, "did not unlocked, (completed pay)");

        uint256 nft_amount = balanceOf(msg.sender, id);

        _burn(msg.sender, id, nft_amount);

        payable(msg.sender).call{value: nft_price[id] * nft_amount }("");
    }

    function our_mint(address user, uint256 id, uint256 amount) internal {

        _mint(user, id, amount, "");
        fnftsCreated++;
        
    }
}