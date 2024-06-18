// @title Uniswap Exchange Interface V1
// @notice Source code found at https://github.com/uniswap
// https://github.com/Uniswap/v1-contracts/blob/c10c08d81d6114f694baa8bd32f555a40f6264da/contracts/uniswap_exchange.vy
// rewrite this code for reentrancy example
pragma solidity 0.7.0;

import "./token.sol";
import "node_modules/openzeppelin-solidity-3.4.0/introspection/IERC1820Registry.sol";
import "node_modules/openzeppelin-solidity-3.4.0/introspection/ERC1820Implementer.sol";
import "node_modules/openzeppelin-solidity-3.4.0/token/ERC777/IERC777Sender.sol";
import "node_modules/openzeppelin-solidity-3.4.0/token/ERC777/IERC777Recipient.sol";


contract Exchange {
    MyERC777Token token;
    constructor(address _token) payable {
        token = MyERC777Token(_token);
    }
    
    function tokenToEthInput(uint256 tokensSold) public returns (uint256) {
        address buyer = msg.sender;
        address recipient = msg.sender;
        uint256 tokenReserve = token.balanceOf(address(this)); // this value did not updated should be increased 
        uint256 ethBought = getInputPrice(tokensSold, tokenReserve, address(this).balance);
        
        require(address(this).balance >= ethBought, "Insufficient contract balance.");
        
        // Send ETH to the recipient
        // (bool sent, ) = recipient.call{value: ethBought}("");
        // require(sent, "Failed to send Ether");

        // Transfer tokens from the buyer to this contract
        bool isTransferFromSuccess = token.transferFrom(buyer, address(this), tokensSold);
        require(isTransferFromSuccess, "Token transfer failed.");


        // !!!!!!!!!!!!! this two line are changed from original code but 
        // original vuln from tokenToTOkenInput is doing this thing inside of the function.
        (bool sent, ) = recipient.call{value: ethBought}("");
        require(sent, "Failed to send Ether");

        return ethBought;
    }

    function ethToTokenInput() public payable returns (uint256) {
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethReserve = address(this).balance - msg.value; // ETH reserve before the transaction
        uint256 tokensBought = getInputPrice(msg.value, ethReserve, tokenReserve);

        require(tokensBought >= 1, "Insufficient tokens bought");
        require(token.transfer(msg.sender, tokensBought), "Token transfer failed");
        return tokensBought;
    }

      // Function to calculate input price, assuming it exists in this contract
    function getInputPrice(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 997;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        return numerator / denominator;
    }
}


