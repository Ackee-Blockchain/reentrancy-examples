from wake.testing import *
from typing import List

from pytypes.contracts.erc777.token import MyERC777Token
from pytypes.contracts.erc777.vault import Exchange
from pytypes.contracts.erc777.attacker import Attacker
from pytypes.contracts.erc777.ERC1820Registry import ERC1820Registry

@default_chain.connect()
def test_default():
    print("---------------------ERC777 Reentrancy---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]

    regs = ERC1820Registry.deploy()
    erc777 = MyERC777Token.deploy(1000*(10**18), [victim], regs.address, from_=victim)

    exchange = Exchange.deploy(erc777, value="1000 ether")

    erc777.transfer(exchange, 1000*(10**18), from_=victim)
    
    attacker_contract = Attacker.deploy(regs.address, erc777.address, exchange.address, value="100 ether", from_=attacker)
    print("Vault token  : ", erc777.balanceOf(exchange))
    print("Vault eth    : ", exchange.balance)
    print("Attacker token: ", erc777.balanceOf(attacker_contract))
    print("Attacker eth  : ", attacker_contract.balance)

    print("---------------------attack---------------------")

    attacker_contract.attack(from_=attacker)
    print("Vault token  : ", erc777.balanceOf(exchange))
    print("Vault eth    : ", exchange.balance)
    print("Attacker token: ", erc777.balanceOf(attacker_contract))
    print("Attacker eth  : ", attacker_contract.balance)