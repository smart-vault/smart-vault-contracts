import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    const VaultNftToken = await deployments.deploy("VaultNftToken", {
        args: [],
        from: deployer,
        log: true,
    });
    console.log("deployed VaultNftToken at %s", VaultNftToken.address);

};

export default func;

// npx hardhat deploy --network rinkeby
// npx hardhat verify --network polygon 0xaddress