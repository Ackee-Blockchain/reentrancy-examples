// SPDX-License-Identifier: GNU-GPL v3.0 or later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Vault is ERC1155 {
    mapping(uint256 => uint256) public idToRequiredEth;
    mapping(uint256 => bool) public payed;
    mapping(uint256 => uint256) public nftPrice;

    uint256 public fnftsCreated = 0;

    function getNftPrice(uint256 id) public view returns (uint256) {
        return nftPrice[id];
    }

    function getRquire(uint256 id) public view returns (uint256) {
        return idToRequiredEth[id];
    }

    function getNextId() public view returns (uint256) {
        return fnftsCreated;
    }

    constructor() payable ERC1155("") {}

    function create(uint256 nftAmount, uint256 value) public returns (uint256) {
        require(value > 0, "value should be greater than 0");
        uint256 id = getNextId();
        idToRequiredEth[id] = value * nftAmount;
        nftPrice[id] = value;
        mint(msg.sender, id, nftAmount);
        return id;
    }

    function payEth(uint256 id) public payable {
        require(payed[id] == false, "already payed");
        require(msg.value == idToRequiredEth[id], "incorrect eth amount");
        payed[id] = true;
    }

    function withdraw(uint256 id) public {
        require(payed[id] == true, "did not unlocked, (completed pay)");

        uint256 nftAmount = balanceOf(msg.sender, id);

        _burn(msg.sender, id, nftAmount);

        (bool success,) = msg.sender.call{value: nftPrice[id] * nftAmount}("");
        require(success, "Transfer failed.");
    }

    function mint(address user, uint256 id, uint256 amount) internal {
        _mint(user, id, amount, "");
        fnftsCreated++;
    }
}
