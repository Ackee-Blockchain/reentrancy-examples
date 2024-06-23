from wake.testing import *

from pytypes.contracts.flashloan.Token import Token
from pytypes.contracts.flashloan.Vault import Vault
from pytypes.contracts.flashloan.Attacker import Attacker


@default_chain.connect()
def test_default():
    print("---------------------Reentrancy in Flash Loan---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]

    token = Token.deploy(11*10**18, from_=victim)
    vault= Vault.deploy(token, from_=victim)
    attacker_contract = Attacker.deploy(vault, token, from_ =attacker)
    token.transfer(vault, 10*10**18, from_=victim)

    print("Vault token  : ", token.balanceOf(vault))
    print("Attacker token: ", token.balanceOf(attacker_contract))

    print("---------------------attack---------------------")
    tx = attacker_contract.attack(from_=attacker)
    print(tx.call_trace)

    print("Vault token  : ", token.balanceOf(vault))
    print("Attacker token: ", token.balanceOf(attacker_contract))
