from wake.testing import *
from typing import List

from pytypes.contracts.erc721.vault import Masks
from pytypes.contracts.erc721.attacker import Attacker

# for running this, you need to copy paste from erc777modified.sol to erc777 path in the node_module

@default_chain.connect()
def test_default():
    print("---------------------ERC721 Reentrancy---------------------")
    victim = default_chain.accounts[0]
    attacker = default_chain.accounts[1]

    hashmask = Masks.deploy(from_=victim)
    attackerContract = Attacker.deploy(hashmask, value="100 ether", from_=attacker)

    print("this vault should be able to mint up to 20 NFT at once.")
    print("---------------------attack---------------------")

    attackerContract.attack(from_=attacker)
    print("Attacker mint NFT :", attackerContract.nftCount())

