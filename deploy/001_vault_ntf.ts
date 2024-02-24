import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    const VaultNftTokenV2 = await deployments.deploy("VaultNftTokenV2", {
        args: [],
        from: deployer,
        log: true,
    });
    console.log("deployed VaultNftTokenV2 at %s", VaultNftTokenV2.address);

};

export default func;

// npx hardhat deploy --network rinkeby
// npx hardhat verify --network polygon 0xaddress