from wake.testing import *

from pytypes.contracts.crossfunctionreentrancy.Vault import Vault
from pytypes.contracts.crossfunctionreentrancy.Attacker import Attacker
from pytypes.contracts.crossfunctionreentrancy.Attacker import Attacker2

@default_chain.connect()
def test_default():
    print("---------------------Cross Function Reentrancy---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    vault_contract = Vault.deploy(from_=victim)
    vault_contract.deposit(from_=victim, value="10 ether")

    attacker_contract = Attacker.deploy(vault_contract.address, from_=attacker , value="1 ether")
    attacker2_contract = Attacker2.deploy(vault_contract.address, from_=attacker)
    attacker_contract.setattacker2(attacker2_contract.address, from_=attacker)

    print("Vault balance   : ", vault_contract.balance)
    print("Attacker balance: ", attacker_contract.balance)

    print("----------Attack----------")
    tx = attacker_contract.attack(from_=attacker)
    print(tx.call_trace)

    print("Vault balance   : ", vault_contract.balance)
    print("Attacker balance: ", attacker_contract.balance)
