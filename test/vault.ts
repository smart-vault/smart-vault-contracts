import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";
import { MockToken, MockToken__factory, VaultNftToken, VaultNftToken__factory } from "../typechain-types";

describe("vaultNftToken", function () {
    let vaultNFT: VaultNftToken;
    let mockToken: MockToken;
    let owner: Signer;
    let addr1: Signer;

    beforeEach(async () => {
        [owner, addr1] = await ethers.getSigners();

        const mockTokenFactory = new MockToken__factory(owner);
        mockToken = await mockTokenFactory.deploy(); 
        mockToken.mint(owner, BigInt('10000000000000000000'));
        
        const NftFactory = new VaultNftToken__factory(owner);
        vaultNFT = await NftFactory.deploy(); 
        await vaultNFT.setToken(mockToken);

    });

  describe("minting", () => {
    it("should mint a new NFT", async () => {
      const tokenId = 0;
      await vaultNFT.safeMint(owner);
      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await owner.getAddress());
    });

    it("should not allow non-owner to mint a new NFT", async () => {
      const tokenId = 0;
      const [add, nonOwner] = await ethers.getSigners();
      await expect(vaultNFT.connect(addr1).safeMint(addr1)).to.be.revertedWith("Ownable: caller is not the owner");
    });

  });

  describe("burning", () => {
    it("should burn an existing NFT", async () => {
      const tokenId = 0;
      await vaultNFT.safeMint(owner);
      await vaultNFT.burn(tokenId);
      await expect(vaultNFT.ownerOf(tokenId)).to.be.revertedWith("ERC721: invalid token ID");
    });

    it("should not allow non-owner to burn an existing NFT", async () => {
      const tokenId = 0;
      const [, nonOwner] = await ethers.getSigners();
      await vaultNFT.safeMint(owner);
      await expect(vaultNFT.connect(nonOwner).burn(tokenId)).to.be.revertedWith("ERC721: caller is not token owner or approved");
    });
  });

  describe("metadata", () => {
    it("should return the correct base URI", async () => {
      expect(await vaultNFT.baseURI()).to.equal("ipfs://bafkreibrp53aqq6eltpjotm4spazvq42n555aqwtwck67monwzuogmyzya");
    });

    it("should return the correct token URI", async () => {
      const tokenId = 0;
      const expectedURI = "ipfs://bafkreibrp53aqq6eltpjotm4spazvq42n555aqwtwck67monwzuogmyzya";
      await vaultNFT.safeMint(owner);
      expect(await vaultNFT.tokenURI(tokenId)).to.equal(expectedURI);
    });
  });

  describe("mintVault", () => {
    it("should return the correct base URI", async () => {
      expect(await vaultNFT.baseURI()).to.equal("ipfs://bafkreibrp53aqq6eltpjotm4spazvq42n555aqwtwck67monwzuogmyzya");
    });

    it("should fail then add to allow list and successfully mint", async () => {
      const tokenId = 0;
      const mintfee = 1000;
      const expectedURI = "ipfs://bafkreibrp53aqq6eltpjotm4spazvq42n555aqwtwck67monwzuogmyzya";
      expect(await mockToken.allowance(await owner.getAddress(), await vaultNFT.getAddress())).to.equal(0);
      await mockToken.approve(await vaultNFT.getAddress(),BigInt('10000000000000000000'));
      await vaultNFT.setMintFee(mintfee);
      expect(await mockToken.allowance(await owner.getAddress(), await vaultNFT.getAddress())).to.equal(BigInt('10000000000000000000') );
      expect(await vaultNFT.checkTokenApproval(await owner.getAddress())).to.equal(BigInt('10000000000000000000') );
      expect(await mockToken.balanceOf(await owner.getAddress())).to.equal(BigInt('10000000000000000000'));
      expect(await mockToken.balanceOf(await vaultNFT.getAddress())).to.equal(0);
      
      
      expect(vaultNFT.mintVault(owner)).to.be.revertedWith("AlllowlistOwner: caller is not in the AllowList");
      expect(vaultNFT.ownerOf(tokenId)).to.revertedWith("ERC721: invalid token ID");

      expect(await vaultNFT.isAllowlisted(await owner.getAddress())).to.equal(false);
      await vaultNFT.setAllowlistUser(await owner.getAddress(), true);
      expect(await vaultNFT.isAllowlisted(await owner.getAddress())).to.equal(true);
     
      await vaultNFT.mintVault(addr1);

      expect(await mockToken.balanceOf(await vaultNFT.getAddress())).to.equal(mintfee);
      expect(await vaultNFT.tokenURI(tokenId)).to.equal(expectedURI);
      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await addr1.getAddress());
      
    });

    it("should vault mint with disabled allow list", async () => {
      const tokenId = 0;
      const mintfee = 1000;
      const expectedURI = "ipfs://bafkreibrp53aqq6eltpjotm4spazvq42n555aqwtwck67monwzuogmyzya";
      expect(await mockToken.allowance(await owner.getAddress(), await vaultNFT.getAddress())).to.equal(0);
      await mockToken.approve(await vaultNFT.getAddress(),BigInt('10000000000000000000'));
      await vaultNFT.setMintFee(mintfee);
      expect(await mockToken.allowance(await owner.getAddress(), await vaultNFT.getAddress())).to.equal(BigInt('10000000000000000000') );
      expect(await vaultNFT.checkTokenApproval(await owner.getAddress())).to.equal(BigInt('10000000000000000000') );
      expect(await mockToken.balanceOf(await owner.getAddress())).to.equal(BigInt('10000000000000000000'));
      expect(await mockToken.balanceOf(await vaultNFT.getAddress())).to.equal(0);
      
      await vaultNFT.disableAllowList();
      await vaultNFT.mintVault(owner);

      expect(await mockToken.balanceOf(await vaultNFT.getAddress())).to.equal(mintfee);
      expect(await vaultNFT.tokenURI(tokenId)).to.equal(expectedURI);
      expect(await vaultNFT.ownerOf(tokenId)).to.equal(await owner.getAddress());
    });

  });
});