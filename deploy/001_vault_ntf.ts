import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    // const VaultNft = await deployments.deploy("VaultNft", {
    //     args: [],
    //     from: deployer,
    //     log: true,
    // });
    // console.log("deployed VaultNft at %s", VaultNft.address);

};

export default func;

// npx hardhat deploy --network rinkeby
// npx hardhat verify --network polygon 0xaddress