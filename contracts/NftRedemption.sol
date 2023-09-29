// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./IVaultNft.sol";
import './AllowlistOwnable.sol';

contract NftRedemption is ERC721Holder, AllowlistOwnable {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    enum EscrowStatus {Default, Created, Offered, Redeemed, Cancelled }
    struct Escrow {
        uint256 tokenId;
        address owner;
        uint256 amount;
        uint256 deadline;
        EscrowStatus status;
    }

    address public nftAddress;

    EnumerableSet.UintSet private tokensInEscrow;
    mapping(uint256 => Escrow) private escrows;
    mapping(address => EnumerableSet.UintSet) private userEscrows;

    event EscrowCreated(uint256 indexed tokenId, address indexed owner);
    event EscrowOffer(uint256 indexed tokenId, uint256 amount, uint256 deadline);
    event EscrowRedeemed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event EscrowCancelled(uint256 indexed tokenId, address indexed owner);

    //Accept funds for paying escrow out
    function fund() public payable {}
    receive() external payable {}

    // admin if over funded
    function withdraw(address payable destination, uint amount) external onlyOwner {
        require(address(this).balance >= amount, "balance value needs to be >= amount");
        Address.sendValue(destination, amount);
    }

    function preAuthorizeBurn(address _nftAddress) public onlyOwner {
        nftAddress = _nftAddress; 
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

    function getUserEscrows(address user) public view returns (Escrow[] memory) {
        uint256[] memory escrowIds = getUserEscrowsId(user);
        if(escrowIds.length == 0) return new Escrow[](0);

        Escrow[] memory escrowsArr = new Escrow[](escrowIds.length);
        for (uint256 i = 0; i < escrowIds.length; i++) {
            escrowsArr[i] = escrows[escrowIds[i]];
        }
        return escrowsArr;
    }

    function getUserEscrowsId(address user) public view returns (uint256[] memory) {
        uint256[] memory escrowIds = userEscrows[user].values();
        return escrowIds;
    }

    function getEscrowedTokenId() public view returns (uint256[] memory) {
        uint256[] memory escrowIds = tokensInEscrow.values();
        return escrowIds;
    }

    function createEscrow(
        uint256 tokenId
    ) external returns (bool) {
        IVaultNFT nft = IVaultNFT(nftAddress);
        // Lets check if the sender is the owner of the NFT
        require(nft.ownerOf(tokenId) ==  _msgSender(), "NftEscrow: sender is not owner");
        
        // Lets take the NFT first (this will fail if the sender is not the owner)
        nft.authorizedTransferFrom( _msgSender(), address(this), tokenId);

        // Lets set the state of the escrow
        Escrow storage escrow = escrows[tokenId];
        require(escrow.status != EscrowStatus.Redeemed, "NftEscrow: NFT is not redeemed");

        EnumerableSet.UintSet storage _userEscrows = userEscrows[ _msgSender()];
        //Add to sets
        _userEscrows.add(tokenId);
        EnumerableSet.UintSet storage _tokensInEscrow = tokensInEscrow;
        _tokensInEscrow.add(tokenId);

        // Set / Reset Escrow
        escrow.tokenId = tokenId;
        escrow.owner =  _msgSender();
        escrow.amount = 0;
        escrow.status = EscrowStatus.Created;
        escrow.deadline = block.timestamp;
        
        emit EscrowCreated(tokenId,  _msgSender());
        return true;
    }

    function offerEscrow (        
        uint256 tokenId,
        uint256 amount,
        uint256 deadline) public onlyOwnerOrInAllowList returns (bool) {

        ERC721Burnable nft = ERC721Burnable(nftAddress);
        require(nft.ownerOf(tokenId) == address(this), "NftEscrow: contract not NFT owner");

        Escrow storage escrow = escrows[tokenId];
        require((escrow.status != EscrowStatus.Redeemed && escrow.status != EscrowStatus.Cancelled), "NftRedemption: escrow is already redeemed or cancelled");
        require(amount <= address(this).balance, "NftEscrow: amount needs sufficent funds in contract");

        escrow.amount = amount;
        escrow.deadline = deadline;
        escrow.status = EscrowStatus.Offered;

        emit EscrowOffer(tokenId, amount, deadline);
        return true;
    }

    function redeemEscrow(uint256 tokenId, uint256 amount, uint256 deadline) external returns (bool) {
        ERC721Burnable nft = ERC721Burnable(nftAddress);
        require(nft.ownerOf(tokenId) == address(this), "NftEscrow: contract not NFT owner");

        Escrow storage escrow = escrows[tokenId];
        require(escrow.amount == amount, "NftEscrow: amounts does not match, expired offer data");
        require(escrow.deadline == deadline, "NftEscrow: deadline does not match, expired offer data");
        require(escrow.deadline >= block.timestamp, "NftEscrow: deadline has expired, cancel and recreate escrow");
        require(escrow.owner ==  _msgSender(), "NftEscrow: new to be NFT escrow owner");
        require(escrow.status == EscrowStatus.Offered, "NftEscrow: is not offered");
        require(address(this).balance >= escrow.amount, "NftEscrow: insufficient funds");
        
        nft.burn(tokenId);
        Address.sendValue(payable(escrow.owner), escrow.amount);
        escrow.status = EscrowStatus.Redeemed;
        // Set redeem deadline to now when claimed
        escrow.deadline = block.timestamp;

        emit EscrowRedeemed(tokenId, escrow.owner, escrow.amount);
        return true;
    }

    function cancelEscrow(uint256 tokenId) external returns (bool) {
        ERC721Burnable nft = ERC721Burnable(nftAddress);
        require(nft.ownerOf(tokenId) == address(this), "NftEscrow: contract not NFT owner");

        Escrow storage escrow = escrows[tokenId];
        require(( _msgSender() == escrow.owner || isOwnerOrInAllowlisted(_msgSender())), "NftEscrow: not escrow owner or isOwnerOrInAllowlisted");
        require((escrow.status == EscrowStatus.Offered || escrow.status == EscrowStatus.Created), "NftEscrow: is not offered");

        nft.safeTransferFrom(address(this),  _msgSender(), tokenId);

        // reset state so we know its cancelled
        escrow.deadline = 0;
        escrow.owner = address(0);
        escrow.amount = 0;
        escrow.status = EscrowStatus.Cancelled;
        
        emit EscrowCancelled(tokenId, escrow.owner);
        return true;
    }

    function escrowStatus(uint256 tokenId) external view returns (Escrow memory){
        return escrows[tokenId];
    }
}