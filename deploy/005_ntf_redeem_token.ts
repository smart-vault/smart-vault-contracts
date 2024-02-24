import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    // const NftRedemptionToken = await deployments.deploy("NftRedemptionToken", {
    //     args: [],
    //     from: deployer,
    //     log: true,
    // });
    // console.log("deployed NftRedemptionToken at %s", NftRedemptionToken.address);

};

export default func;

// npx hardhat deploy --network rinkeby
// npx hardhat verify --network polygon 0xaddress

// uccessfully generated 38 typings! mumbai
// Compiled 2 Solidity files successfully
// reusing "VaultNft" at 0xf42d5A9b745179Cb9ED65AD146bBfa592648681d
// deployed VaultNft at 0xf42d5A9b745179Cb9ED65AD146bBfa592648681d
// reusing "NftRedemption" at 0xa82E581DA3174AD1B7A5fb972Dbe493D91c57323
// deployed NftRedemption at 0xa82E581DA3174AD1B7A5fb972Dbe493D91c57323
// reusing "MockToken" at 0x9333675a9dDCb6E8D3A27fEF3914B180fc0f9499
// deployed MockToken at 0x9333675a9dDCb6E8D3A27fEF3914B180fc0f9499
// deploying "VaultNftToken" (tx: 0xa02a9ee2c9b468e877e9f78d5e6d703da5ded17376c181d8414afe3434485aa1)...: deployed at 0x990270f6d10a584E324FBa8D349846f7C9A41B53 with 5421569 gas
// deployed VaultNft at 0x990270f6d10a584E324FBa8D349846f7C9A41B53
// deploying "NftRedemptionToken" (tx: 0x428738ac983d62df072ebe44dc8aa9b8feaa89b6421e7256410e24d4f02598b7)...: deployed at 0x422e26706fD837aE45c1EA3970bC86C72493939d with 3476994 gas
// deployed NftRedemptionToken at 0x422e26706fD837aE45c1EA3970bC86C72493939d