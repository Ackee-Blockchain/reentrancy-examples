from wake.testing import *

from pytypes.contracts.singlefunctionreentrancy.vault import single_function_reentrancy
from pytypes.contracts.singlefunctionreentrancy.attacker import attack_single_function_reentrancy


def single_function_reentrancy_attack():
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    
    sfContract = single_function_reentrancy.deploy(from_=victim)

    sfContract.deposit(from_=victim, value="10 ether")
    atContract = attack_single_function_reentrancy.deploy(sfContract.address, from_=attacker, value="1 ether")

    print("Vault balance   : ", sfContract.balance)
    print("Attacker balance: ", atContract.balance)

    print("----------Attack----------")
    atContract.attack(from_=attacker)

    print("Vault balance   : ", sfContract.balance)
    print("Attacker balance: ", atContract.balance)

@default_chain.connect()
def test_default():
    print("")
    single_function_reentrancy_attack()


