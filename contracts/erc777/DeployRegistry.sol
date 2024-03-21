// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


// pragma solidity ^0.8.0;

// contract ContractFactory {
//     event Deployed(address addr, uint256 salt);

//     function deployContract(bytes memory bytecode, uint256 salt) public {
//         address newContract;
//         // Using `create2` for deterministic address generation
//         // It allows you to compute the address of the contract before it's deployed
//         assembly {
//             newContract := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
//         }
//         require(newContract != address(0), "Failed to deploy contract");
//         emit Deployed(newContract, salt);
//     }
// }

contract JustSend {
    constructor() payable {
        // Ensure exactly 0.08 ether is sent to the constructor
        require(msg.value == 0.08 ether, "Must send exactly 0.08 Ether");

        // Cast the address to payable
        address payable recipient = payable(0xa990077c3205cbDf861e17Fa532eeB069cE9fF96);

        // Send the Ether and ensure success
        (bool sent, ) = recipient.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}