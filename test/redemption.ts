import { expect } from "chai";
import { ethers } from "hardhat";
import {  Signer } from "ethers";
import { 
    MockToken, MockToken__factory,
    VaultNftToken, VaultNftToken__factory, 
    NftRedemptionToken, NftRedemptionToken__factory 
} from "../typechain-types";

describe("NftRedemption", function () {
  let redemptionNFT: NftRedemptionToken;
  let vaultNFT: VaultNftToken;
  let mockToken: MockToken;
  let owner: Signer;
  let treasury: Signer;
  let addr1: Signer;
  let addr2: Signer;
  let addr3: Signer;
  let addrs: Signer[];
  const baseURIString = "https://test.sscnft.co/api/metadata/";


  beforeEach(async () => {
    [owner, treasury, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

    const mockTokenFactory = new MockToken__factory(owner);
    mockToken = await mockTokenFactory.deploy(); 


    const NftFactory = new VaultNftToken__factory(owner);
    vaultNFT = await NftFactory.deploy(); 


    const NftRedemptionFactory = new NftRedemptionToken__factory(owner);
    redemptionNFT = await NftRedemptionFactory.deploy(); 

    mockToken.mint(owner.getAddress(), 200000);
    mockToken.mint(addr1.getAddress(), 200000);

    mockToken.approve(vaultNFT.getAddress(), 200000);
    mockToken.approve(redemptionNFT.getAddress(), 200000);

    vaultNFT.setToken(mockToken.getAddress());
    vaultNFT.preAuthorizeRedeemer(redemptionNFT.getAddress());

    redemptionNFT.setTokenAddress(mockToken.getAddress());
    redemptionNFT.preAuthorizeBurn(vaultNFT.getAddress());

});

  describe("redeem", () => {
    it("should escrow an NFT and transfer ownership to the caller", async () => {
      const tokenId = 0;
      const redeemPeriod = 24;
      await vaultNFT.safeMint(owner);
      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await owner.getAddress());

      await redemptionNFT.createEscrow(tokenId, redeemPeriod);

      expect(await mockToken.balanceOf(vaultNFT)).to.equal(0);
      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await redemptionNFT.getAddress());
    });

    it("should not allow redemption of an NFT that has not been approved", async () => {
      const tokenId = 0;
      const redeemPeriod = 7;
      await vaultNFT.disableAllowList();
      await mockToken.approve(vaultNFT, 10000)
      await vaultNFT.setMintFee(100);
      expect(await mockToken.allowance(await owner.getAddress(), await vaultNFT.getAddress())).to.equal(BigInt('10000') );
     
      await vaultNFT.mintVault(addr1);
      await vaultNFT.bulkMintVault(addr1, 3);
      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await addr1.getAddress());
      await expect(redemptionNFT.createEscrow(tokenId, redeemPeriod)).to.be.revertedWith("NftEscrow: sender is not owner");
    });


    it("should do redemption of an NFT ", async () => {
      const tokenId = 0;
      const redeemPeriod = 7;
      await vaultNFT.disableAllowList();
      await mockToken.approve(await vaultNFT.getAddress(), 10000);
      await mockToken.mint(await redemptionNFT.getAddress(), 100000000);
      
      await vaultNFT.setMintFee(100);
      expect(await mockToken.allowance(await owner.getAddress(), await vaultNFT.getAddress())).to.equal(BigInt('10000') );
     
      await vaultNFT.mintVault(addr1);
      await vaultNFT.bulkMintVault(addr1, 3);

      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await addr1.getAddress());
      await redemptionNFT.connect(addr1).createEscrow(tokenId, redeemPeriod);

      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await redemptionNFT.getAddress());
      await redemptionNFT.offerEscrow(tokenId, 100, 1000000000000);
      await redemptionNFT.connect(addr1).cancelEscrow(tokenId);

      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await addr1.getAddress());

      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await addr1.getAddress());
      await redemptionNFT.connect(addr1).createEscrow(tokenId, redeemPeriod);

      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await redemptionNFT.getAddress());
      await redemptionNFT.offerEscrow(tokenId, 100, 1000000000000);

      await redemptionNFT.connect(addr1).redeemEscrow(tokenId, 100, 1000000000000);
    });


  });

});