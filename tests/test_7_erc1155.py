from wake.testing import *

from pytypes.contracts.erc1155.vault import Vault
from pytypes.contracts.erc1155.attacker import Attacker

@default_chain.connect()
def test_default():
    print("---------------------ERC1155 Reentrancy---------------------")
    user1 = default_chain.accounts[0]
    user2 = default_chain.accounts[1]
    attacker = default_chain.accounts[1]

    print("------------------------Expected Usage--------------------------------------")
    vault = Vault.deploy(value="1000 ether")

    ret = vault.create(100, 1*10**18, from_= user1)

    token_id = ret.return_value
    
    print("user1 holding token(", token_id, ") with amount: ", vault.balanceOf(user1, token_id))
    print("price of token(", token_id, ") is ", vault.getNftPrice(token_id))

    vault.safeTransferFrom(user1, user2, token_id, 40, b"", from_=user1)

    print("user1 token amount:", vault.balanceOf(user1, token_id))
    print("user1 token amount:", vault.balanceOf(user2, token_id))

    vault.payEth(token_id, from_=user1, value="100 ether")
    print("we unlocked by paying")

    print("user1 going to withdraw")
    ret = vault.withdraw(token_id, from_=user1)
    print(ret.call_trace)

    print("user2 going to withdraw")
    ret = vault.withdraw(token_id, from_ = user2)
    print(ret.call_trace)

@default_chain.connect()
def test_attack():
    attacker = default_chain.accounts[1]

    vault2 = Vault.deploy(value="1000 ether")
    attacker_contract = Attacker.deploy(vault2, value="10 ether")
  
    print("attacker address: ", attacker_contract.address)
    print("Vault balance   : ", vault2.balance)
    print("Attacker balance: ", attacker_contract.balance)

    print("---------------------attack---------------------")
    tx = attacker_contract.attack(from_=attacker)
    print(tx.call_trace)
    print(tx.return_value)

    print("Vault balance   : ", vault2.balance)
    print("Attacker balance: ", attacker_contract.balance)
