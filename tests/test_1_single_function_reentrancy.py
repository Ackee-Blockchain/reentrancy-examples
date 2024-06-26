from wake.testing import *

from pytypes.contracts.singlefunctionreentrancy.Vault import Vault
from pytypes.contracts.singlefunctionreentrancy.Attacker import Attacker

@default_chain.connect()
def test_default():
    print("---------------------Single Function Reentrancy---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    vault = Vault.deploy(from_=victim)
    vault.deposit(from_=victim, value="10 ether")

    attacker_contract = Attacker.deploy(vault.address, from_=attacker, value="1 ether")

    print("Vault balance   : ", vault.balance)
    print("Attacker balance: ", attacker_contract.balance)

    print("----------Attack----------")
    tx = attacker_contract.attack(from_=attacker)
    print(tx.call_trace)

    print("Vault balance   : ", vault.balance)
    print("Attacker balance: ", attacker_contract.balance)
