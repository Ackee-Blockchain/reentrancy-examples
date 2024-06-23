from wake.testing import *

from pytypes.contracts.crosscontractreentrancy.Token import  CCRToken
from pytypes.contracts.crosscontractreentrancy.Vault import Vault
from pytypes.contracts.crosscontractreentrancy.Attacker import Attacker1
from pytypes.contracts.crosscontractreentrancy.Attacker import Attacker2

@default_chain.connect()
def test_default():
    print("---------------------Cross Contract Reentrancy---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    vault = Vault.deploy(from_=victim)
    token = CCRToken.deploy( vault.address ,from_=victim)
    vault.setToken(token.address)
    vault.deposit(from_=victim, value="10 ether")

    attacker_contract = Attacker1.deploy(vault.address, token.address, from_=attacker, value="1 ether")
    attacker2_contract = Attacker2.deploy(vault.address, token.address, from_=attacker)
    attacker_contract.setattacker2(attacker2_contract.address, from_=attacker)

    print("Vault balance  : ", vault.balance)
    print("Attacker balace: ", attacker_contract.balance)

    print("----------Attack----------")
    tx = attacker_contract.attack(from_=attacker)
    print(tx.call_trace)

    print("Vault balance   : ", vault.balance)
    print("Attacker balance: ", attacker_contract.balance)
