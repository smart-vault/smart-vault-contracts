import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deployer } = await getNamedAccounts();

    // const NftRedemption = await deployments.deploy("NftRedemption", {
    //     args: [],
    //     from: deployer,
    //     log: true,
    // });
    // console.log("deployed NftRedemption at %s", NftRedemption.address);

};

export default func;

// npx hardhat deploy --network rinkeby
// npx hardhat verify --network polygon 0xaddress