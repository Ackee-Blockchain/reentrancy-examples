from wake.testing import *

from pytypes.contracts.readonlyreentrancy.victim import VictimPool, VulnPool
from pytypes.contracts.readonlyreentrancy.attacker import Attacker

@default_chain.connect()
def test_default():
    print("---------------------Read Only Reentrancy---------------------")
    vuln_pool = VulnPool.deploy() 
    victim_pool = VictimPool.deploy(vuln_pool.address)


    vuln_pool.deposit(value="10 ether", from_=default_chain.accounts[2]) # general user
    victim_pool.deposit(value="10 ether", from_=default_chain.accounts[2]) # general user

    attacker = Attacker.deploy(vuln_pool.address, victim_pool.address,value="1 ether", from_=default_chain.accounts[0])

    print("---------------------attack---------------------")
    print("Attacker balance: ", attacker.balance)

    tx = attacker.attack()
    print("Attacker balance: ", attacker.balance)
    print(tx.call_trace)

    

