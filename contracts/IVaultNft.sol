// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVaultNFT is IERC721 { 

    function authorizedTransferFrom(address from, address to, uint256 tokenId) external;

    function authorizedBurn(uint256 tokenId) external;

}