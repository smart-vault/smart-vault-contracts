import { deployments, ethers } from "hardhat";
import { VaultNft } from "../typechain-types";

async function main() {
  
  const yieldVaultFactory = await ethers.getContractFactory("VaultNft");
  const deployedYiedler = await deployments.get("VaultNft");
  const VaultNft = yieldVaultFactory.attach(deployedYiedler.address) as VaultNft;
  console.log("VaultNft name:",  await VaultNft.name());
 

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
