// SPDX-License-Identifier: private
pragma solidity ^0.8.0;

// https://etherscan.io/address/0xc2c747e0f7004f9e8817db2ca4997657a7746928#code
// Modified source


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";



/**
 * @title Hashmasks contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
// below is original inheritance, the important thing is this is IERC721.

//contract Masks is Context, Ownable, ERC165, IMasks, IERC721Metadata {
contract Masks is Context {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    uint256 public constant MAX_NFT_SUPPLY = 20;


        // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;


    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

     /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor () {
        _name = "MyERC721Token";
        _symbol = "MET";
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_tokenOwners.contains(tokenId), "ERC721: owner query for nonexistent token");
        return _tokenOwners.get(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }


    /**
     * @dev Gets current Hashmask Price
     */
    function getNFTPrice() public view returns (uint256) {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        uint currentSupply = totalSupply();

        if (currentSupply >= 16381) {
            return 100000000000000000000; // 16381 - 16383 100 ETH
        } else if (currentSupply >= 16000) {
            return 3000000000000000000; // 16000 - 16380 3.0 ETH
        } else if (currentSupply >= 15000) {
            return 1700000000000000000; // 15000  - 15999 1.7 ETH
        } else if (currentSupply >= 11000) {
            return 900000000000000000; // 11000 - 14999 0.9 ETH
        } else if (currentSupply >= 7000) {
            return 500000000000000000; // 7000 - 10999 0.5 ETH
        } else if (currentSupply >= 3000) {
            return 300000000000000000; // 3000 - 6999 0.3 ETH
        } else {
            return 100000000000000000; // 0 - 2999 0.1 ETH 
        }
    }

    /**
    * @dev Mints Masks
    */
    function mintNFT(uint256 numberOfNfts) public payable {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 20, "You may not buy more than 20 NFTs at once");
        require(totalSupply() + numberOfNfts <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getNFTPrice() * numberOfNfts == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

  

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        // emit Transfer(address(0), to, tokenId);
    }

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500535e is returned for accounts without code, i.e., `keccak256('')`
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }


    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}