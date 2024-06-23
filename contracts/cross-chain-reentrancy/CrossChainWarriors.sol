// SPDX-License-Identifier: MIT
// Original: https://gist.github.com/m9800/b1925b259fa7dcd6febc22ebc730b324#file-crosschainwarriors-md
pragma solidity 0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrossChainWarriors is ERC721("CrossChainWarriors", "CCWAR") {
    uint256 public tokenIds;

    address public _validator;

    bool _mintable;

    mapping(uint256 => address) addressByChainId;

    modifier onlyValidator() {
        require(_msgSender() == _validator, "Not a Validator");
        _;
    }

    event CrossChainTransfer(uint256 crossChainId, address contractAddress, bytes message);

    constructor(address validator, bool mintable) {
        _validator = validator;
        tokenIds++;
        _mintable = mintable;
    }

    function mint(address to) public returns (uint256) {
        require(_mintable, "Minting is disabled");
        uint256 newWarriorId = tokenIds;
        _safeMint(to, newWarriorId);
        tokenIds++;

        return newWarriorId;
    }

    /**
     * @dev Useful for cross-chain minting
     */
    function _mintId(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    /**
     * @dev Cross-chain functions
     */
    function crossChainTransfer(uint256 crossChainId, address to, uint256 tokenId) external {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // owner of NFT or approved.
        address previousOwner = _update(address(0), tokenId, _msgSender());
        if (previousOwner == address(0)) {
            revert ERC721InvalidSender(address(0));
        }

        emit CrossChainTransfer(crossChainId, addressByChainId[crossChainId], abi.encode(tokenId, msg.sender, to));
    }

    function crossChainMessage(bytes calldata message) external onlyValidator {
        (uint256 tokenId,, address to) = abi.decode(message, (uint256, address, address));

        _mintId(to, tokenId);
    }

    function addChainAddress(uint256 chainId, address contractAddress) external onlyValidator {
        addressByChainId[chainId] = contractAddress;
    }
}
