from wake.testing import *

from pytypes.contracts.readonlyreentrancy.VictimVault import VictimVault
from pytypes.contracts.readonlyreentrancy.VulnVault import VulnVault
from pytypes.contracts.readonlyreentrancy.Attacker import Attacker

@default_chain.connect()
def test_default():
    print("---------------------Read Only Reentrancy---------------------")
    vuln_pool = VulnVault.deploy() 
    victim_pool = VictimVault.deploy(vuln_pool.address)
    vuln_pool.deposit(value="10 ether", from_=default_chain.accounts[2]) # general user
    victim_pool.deposit(value="10 ether", from_=default_chain.accounts[2]) # general user

    attacker = Attacker.deploy(vuln_pool.address, victim_pool.address,value="1 ether", from_=default_chain.accounts[0])

    print("Vault balance:    ", victim_pool.balance)
    print("Attacker balance: ", attacker.balance)
    
    print("---------------------attack---------------------")
    tx = attacker.attack()
    print(tx.call_trace)

    print("Vault balance:    ", victim_pool.balance)   
    print("Attacker balance: ", attacker.balance)
