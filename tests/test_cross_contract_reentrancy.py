from wake.testing import *

from pytypes.contracts.crosscontractreentrancy.vault import ERC20 
from pytypes.contracts.crosscontractreentrancy.vault import cross_contract_reentrancy
from pytypes.contracts.crosscontractreentrancy.attacker import attack_cross_contract_reentrancy
from pytypes.contracts.crosscontractreentrancy.attacker import attack2_cross_contract_reentrancy

# from pytypes.tests.test_contract_reentrancy.sol import test_cross_contract_reentrancy

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
    print("Vault balance: ", sfContract.balance)


    print("----------Attack----------")
    # attacker attck with value = 1*10**18

    atContract.attack(from_=attacker, value=1*10**18)

    print("Vault balance: ", sfContract.balance)
    print("Attacker balance: ", atContract.balance)


@default_chain.connect()
def test_default():
    print("")
    cross_contract_reentrancy_attack()







