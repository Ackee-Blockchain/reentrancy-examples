from wake.testing import *
from pytypes.contracts.crosschainreentrancy.CrossChainWarriors import CrossChainWarriors
from pytypes.contracts.crosschainreentrancy.Attacker import Attacker

chain1 = Chain()
chain2 = Chain()

# Print failing tx call trace
def revert_handler(e: TransactionRevertedError):
    if e.tx is not None:
        print(e.tx.call_trace)

def relay(dist_worrior: CrossChainWarriors,dist_validator: Account,  events: List):
    for event in events:
        if isinstance(event, CrossChainWarriors.CrossChainTransfer):
            assert event.contractAddress == dist_worrior.address
            dist_worrior.crossChainMessage(event.message, from_=dist_validator)

@chain1.connect()
@chain2.connect()
@on_revert(revert_handler)
def test_expected_usage():
    print("----------- Cross Chain Reentrancy --------------")
    print("----------- Expected Usage --------------")
    validator_chain1 = chain1.accounts[1]
    validator_chain2 = chain2.accounts[1]
    user1_chain1 = chain1.accounts[2]
    user1_chain2 = chain2.accounts[2]
    chain1_warrior = CrossChainWarriors.deploy(validator_chain1, True, chain=chain1)
    chain2_warrior = CrossChainWarriors.deploy(validator_chain2, False, chain=chain2)
    chain1_warrior.addChainAddress(chain2.chain_id, chain2_warrior.address, from_=validator_chain1)
    chain2_warrior.addChainAddress(chain1.chain_id, chain1_warrior.address, from_=validator_chain2)
    # initialization done.

    tx = chain1_warrior.mint(user1_chain1)
    token_id = tx.return_value

    print("Chain1: owner of tokenId = ", token_id, " is ", chain1_warrior.ownerOf(token_id))
    with must_revert(CrossChainWarriors.ERC721NonexistentToken):
        chain2_warrior.ownerOf(token_id)
    print("Chain2: owner of tokenId = ", token_id, " is None")# confirmed by reverting the ownerOf call

    print("Inter chain transfer: Chain1 -> Chain2")
    tx = chain1_warrior.crossChainTransfer(chain2.chain_id, user1_chain2.address, token_id, from_=user1_chain1)
    relay(chain2_warrior, validator_chain2, tx.events)


    with must_revert(CrossChainWarriors.ERC721NonexistentToken):
        chain1_warrior.ownerOf(token_id)
    print("Chain1: owner of tokenId = ", token_id, " is None")# confirmed by reverting the ownerOf call
    print("Chain2: owner of tokenId = ", token_id, " is ", chain2_warrior.ownerOf(token_id))


@chain1.connect()
@chain2.connect()
@on_revert(revert_handler)
def test_attack():
    validator_chain1 = chain1.accounts[1]
    validator_chain2 = chain2.accounts[1]
    user1_chain1 = chain1.accounts[2]
    user1_chain2 = chain2.accounts[2]
    chain1_warrior = CrossChainWarriors.deploy(validator_chain1, True, chain=chain1)
    chain2_warrior = CrossChainWarriors.deploy(validator_chain2, False, chain=chain2)
    chain1_warrior.addChainAddress(chain2.chain_id, chain2_warrior.address, from_=validator_chain1)
    chain2_warrior.addChainAddress(chain1.chain_id, chain1_warrior.address, from_=validator_chain2)

    attacker = Attacker.deploy(chain1_warrior.address, chain2_warrior.address,chain2.chain_id, chain=chain1)

    print("----------- Attack --------------")
    tx = attacker.attack()
    relay(chain2_warrior, validator_chain2, tx.events)
    token_id = tx.return_value
    print(tx.call_trace)

    print("Chain1: owner of tokenId = ", token_id, " is ", chain1_warrior.ownerOf(token_id))
    print("Chain2: owner of tokenId = ", token_id, " is ", chain2_warrior.ownerOf(token_id))