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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultNftTokenV2 is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AllowlistOwnable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public mintFee = 10000000000000000; // 0.01 token
    uint256 public maxSupply = 12345;
    uint256 public maxBatchMint = 5;

    bool public singleNftMeta = true;
    address public redeemAuthorizer;
    address payable public destination;
    string public baseURI;

    IERC20 public token = IERC20(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);

    constructor() ERC721("VaultNft", "VLT") {
        baseURI = "ipfs://bafkreibrp53aqq6eltpjotm4spazvq42n555aqwtwck67monwzuogmyzya";
    }
    
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

    function setToken(IERC20 _token) public onlyOwner {
        token = IERC20(_token);
        bool tnxSuccess = token.approve(address(this), type(uint256).max);
        require(tnxSuccess, "Failed to tnx tokens");
    }

    // admin to send to treasury
    function withdraw(uint256 amount) external onlyOwner {
        bool transferSuccess = token.transfer(destination, amount);
        require(transferSuccess, "Failed to transfer tokens");
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

    function approveTokenSpend(uint256 amount) public returns (bool success) {
        return token.approve(address(this), amount);
    }

    function checkTokenApproval(address owner) public view returns (uint256 remaining) {
        return token.allowance(owner, address(this));
    }

    function mintVault(address to) public virtual onlyAllowList {
        require(totalSupply() < maxSupply, "Max supply reached");
        bool transferSuccess = token.transferFrom(msg.sender, address(this), mintFee);
        require(transferSuccess, "Failed to transfer tokens");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function bulkMintVault(address to, uint256 amount) public virtual onlyAllowList {
        require(amount <= maxBatchMint, "amount must be less than or equal to the maxBatchMinted");
        require(totalSupply() + amount <= maxSupply, "Max supply reached");

        uint256 totalFee = amount * mintFee;
        bool transferSuccess = token.transferFrom(msg.sender, address(this), totalFee);
        require(transferSuccess, "Failed to transfer tokens");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
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
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}