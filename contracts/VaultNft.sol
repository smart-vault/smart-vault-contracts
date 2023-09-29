// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import './AllowlistOwnable.sol';
import "./IVaultNft.sol";

contract VaultNft is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AllowlistOwnable, ERC721Burnable, IVaultNFT {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public mintFee = 0.01 ether;
    uint256 public maxSupply = 12345;
    uint256 public maxBatchMint = 5;

    bool public singleNftMeta = true;
    address public redeemAuthorizer;
    address payable public destination;
    string public baseURI;

    constructor() ERC721("VaultNft", "VLT") {}
    
    function setMintFee(uint256 _mintFee) public onlyOwner {
        mintFee = _mintFee;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= 0, "Need a valid new max supply");
        maxSupply = newMaxSupply;
    }

    function setMaxBatchMint(uint256 newMaxBatchMint) public onlyOwner {
        require(newMaxBatchMint >= 0, "Need a valid new max mint limit");
        maxBatchMint = newMaxBatchMint;
    }

    function enableAllowList() public onlyOwner {
        _enableAllowList();
    }

    function disableAllowList() public onlyOwner {
        _disableAllowList();
    }

    function setAllowlistUser(address addr, bool isAllowed) public onlyOwner {
        _setAllowlistUser(addr, isAllowed);
    }

    function setSingleNftMeta(bool _singleNftMeta) public onlyOwner {
        singleNftMeta = _singleNftMeta;
    }

    function setBaseUri(string calldata baseUri) public onlyOwner {
        baseURI = baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setDestination(address payable _destination) public onlyOwner {
        destination = _destination;
    }

    // admin to send to treasury
    function withdraw(uint amount) external onlyOwner {
        require(address(this).balance >= amount, "balance value needs to be >= amount");
        Address.sendValue(destination, amount);
    }

    function authorizedTransferFrom(address from, address to, uint256 tokenId) public  {
        require( msg.sender == redeemAuthorizer, "caller is not authorized to transfer");
        super._safeTransfer(from, to, tokenId, "");
    }

    function safeMintUri(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function safeMint(address to) public onlyOwner{
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function mintVault(address to) public payable virtual onlyAllowList {
        require(msg.value >= mintFee, "mint fee not met");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function bulkMintVault(address to, uint256 amount) public payable virtual onlyAllowList {
        require(amount <= maxBatchMint, "amount must be less than or equal to the maxBatchMinted");
        require(msg.value >= (amount * mintFee), "Payable must be at least the amount * mint fee");
        for (uint256 i = 0; i < amount; i++) {
            mintVault(to);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function preAuthorizeRedeemer(address authorizer) public onlyOwner {
        redeemAuthorizer = authorizer;
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function authorizedBurn(uint256 tokenId) public {
        require(msg.sender == redeemAuthorizer, "caller is not authorized to burn");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory base = _baseURI();

        // If singleNftMeta is set, all the metadata is the same return metadata.
        if (singleNftMeta) {
            if (bytes(base).length > 0) {
                return base;
            }
        }

        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
