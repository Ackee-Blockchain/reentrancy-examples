from wake.testing import *

from pytypes.contracts.singlefunctionreentrancy import single_function_reentrancy
from pytypes.contracts.singlefunctionreentrancy import attack_single_function_reentrancy





@default_chain.connect()
def test_default():
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    attacker2 = default_chain.accounts[2]
    user = default_chain.accounts[3]
    
    sfContract = single_function_reentrancy.deploy(from_=victim)



    sfContract.deposit(from_=victim, value=1* 10**18)
    sfContract.deposit(from_=user, value=1* 10**18)

    sfContract.deposit(from_=user, value=1* 10**18)
    
    atContract = attack_single_function_reentrancy.deploy(sfContract.address, from_=attacker)

    print(sfContract.balance)

    atContract.attack(from_=attacker, value=1*10**18)

    print(sfContract.balance)

    print(atContract.balance)
