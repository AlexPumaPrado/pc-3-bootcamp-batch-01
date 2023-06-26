// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MiPrimerNft is ERC721, Pausable, AccessControl, ERC721Burnable, Ownable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public relayer;
    address public gnosisSafeAddress;

    event NftMinted(address indexed minter, address indexed to, uint256 indexed tokenId, string group, string rarity);

    constructor(address _relayer) ERC721("MiPrimerNft", "MPRNFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        relayer = _relayer;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmYAR7NGDpd54ybzHHiGs2gLv7KYkP4Q1BfNXs378VyPYT/";
    }

    function pause() public {
        require(hasRole(PAUSER_ROLE, msg.sender), "MiPrimerNft: must have pauser role to pause");
        _pause();
    }

    function unpause() public {
        require(hasRole(PAUSER_ROLE, msg.sender), "MiPrimerNft: must have pauser role to unpause");
        _unpause();
    }

    function setGnosisSafeAddress(address _gnosisSafeAddress) external onlyOwner {
        gnosisSafeAddress = _gnosisSafeAddress;
    }
modifier onlyRelayer() {
    require(msg.sender == relayer, "MiPrimerNft: Only the Relayer can call this function");
    _;
}
    function mintNft(address to, uint256 tokenId, string memory group, string memory rarity) public onlyRelayer {
        require(hasRole(MINTER_ROLE, msg.sender), "MiPrimerNft: must have minter role to mint");
        require(tokenId >= 1 && tokenId <= 30, "MiPrimerNft: tokenId must be between 1 and 30");

        _safeMint(to, tokenId);
        emit NftMinted(msg.sender, to, tokenId, group, rarity);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
