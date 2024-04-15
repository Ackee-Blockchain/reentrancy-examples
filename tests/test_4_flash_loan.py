from wake.testing import *

from pytypes.contracts.flashloan.token import Token
from pytypes.contracts.flashloan.vault import Vault
from pytypes.contracts.flashloan.attacker import Attacker


@default_chain.connect()
def test_default():
    print("---------------------Flash Loan---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]

    token = Token.deploy(11*10**18, from_=victim)
    vault= Vault.deploy(token, from_=victim)
    attacker_contract = Attacker.deploy(vault, token, from_ =attacker)
    token.transfer(vault, 10*10**18, from_=victim)

    print("Vault token  : ", token.balanceOf(vault))
    print("Attacker token: ", token.balanceOf(attacker_contract))

    print("---------------------attack---------------------")
    attacker_contract.attack(from_=attacker)
    print("Vault token  : ", token.balanceOf(vault))
    print("Attacker token: ", token.balanceOf(attacker_contract))

#   0x0 October 2023
#   Peapods Finance 13 December 2023
