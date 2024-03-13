from wake.testing import *

from pytypes.contracts.singlefunctionreentrancy import single_function_reentrancy
from pytypes.contracts.singlefunctionreentrancy import attack_single_function_reentrancy

from pytypes.contracts.crossfunctionreentrancy import cross_function_reentrancy
from pytypes.contracts.crossfunctionreentrancy import attack_cross_function_reentrancy
from pytypes.contracts.crossfunctionreentrancy import attack2_cross_function_reentrancy


from pytypes.contracts.crosscontractreentrancy import ERC20 
from pytypes.contracts.crosscontractreentrancy import cross_contract_reentrancy
from pytypes.contracts.crosscontractreentrancy import attack_cross_contract_reentrancy
from pytypes.contracts.crosscontractreentrancy import attack2_cross_contract_reentrancy


def single_function_reentrancy_attack():
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    
    sfContract = single_function_reentrancy.deploy(from_=victim)

    sfContract.deposit(from_=victim, value=100* 10**18)
    atContract = attack_single_function_reentrancy.deploy(sfContract.address, from_=attacker)

    print("Contract balance: ", sfContract.balance)

    print("----------Attack----------")
    atContract.attack(from_=attacker, value=1*10**18)

    print("Contract balance: ", sfContract.balance)
    print("Attacker contract balance: ", atContract.balance)

def cross_function_reentrancy_attack():
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    
    sfContract = cross_function_reentrancy.deploy(from_=victim)
    sfContract.deposit(from_=victim, value=10* 10**18)
 
    
    atContract = attack_cross_function_reentrancy.deploy(sfContract.address, from_=attacker)
    atContract2 = attack2_cross_function_reentrancy.deploy(sfContract.address, from_=attacker)

    atContract.setattacker2(atContract2.address, from_=attacker)
    print("Contract balance: ", sfContract.balance)

    print("----------Attack----------")
    atContract.attack(from_=attacker, value=1*10**18)

    print("Contract balance: ", sfContract.balance)
    print("Attacker contract balance: ", atContract.balance)

def cross_contract_reentrancy_attack():
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    
    ccrt = ERC20.deploy("Test", "TST", 18, from_=victim)
    # ccrt.mint(victim, 100* 10**18, from_=victim)
    sfContract = cross_contract_reentrancy.deploy(ccrt.address, from_=victim)
    sfContract.deposit(from_=victim, value=10* 10**18)
 
    
    atContract = attack_cross_contract_reentrancy.deploy(sfContract.address, ccrt.address, from_=attacker)
    atContract2 = attack2_cross_contract_reentrancy.deploy(sfContract.address, ccrt.address, from_=attacker)

    atContract.setattacker2(atContract2.address, from_=attacker)
    print("Contract balance: ", sfContract.balance)

    print("----------Attack----------")
    atContract.attack(from_=attacker, value=1*10**18)

    print("Contract balance: ", sfContract.balance)
    print("Attacker contract balance: ", atContract.balance)


@default_chain.connect()
def test_default():
    single_function_reentrancy_attack()
    print("")
    cross_function_reentrancy_attack()
    print("")
    cross_contract_reentrancy_attack()
    print("")







