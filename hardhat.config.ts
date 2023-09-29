import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

// Load environment variables from .env file
dotenvConfig({ path: resolve(__dirname, "./.env") });

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  namedAccounts: {
    deployer: 0,
  },
  networks: {
    hardhat: {
      chainId: 1337,
      accounts: [
        {
          privateKey: '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
          balance: '10000000000000000000000'
        },
        {
          privateKey: '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
          balance: '10000000000000000000000'
        },
        {
          privateKey: '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a',
          balance: '10000000000000000000000'
        }
      ]
    },
    mumbai: {
      accounts: [process.env.PKEY ?? ''],
      chainId: 80001,
      url: process.env.MUMBAI_RPC_URL,
    },
    matic: {
      accounts: [process.env.PKEY ?? ''],
      url: process.env.MATIC_RPC_URL,
    }
  },
  solidity: "0.8.19",
  etherscan: {
      apiKey: {
        polygonMumbai: process.env.MUMBAI_VERIFY_KEY ?? '',
        polygon:  process.env.MATIC_VERIFY_KEY ?? ''
      }
  },
};

export default config;
