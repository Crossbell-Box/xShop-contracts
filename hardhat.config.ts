import * as dotenv from "dotenv";

import "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";


dotenv.config();

module.exports = {
    solidity: {
        version: "0.8.18",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks: {
        ropsten: {
            url: process.env.ROPSTEN_URL || "",
            accounts: [process.env.PRIVATE_KEY]
        },
        crossbell: {
            url: "https://rpc.crossbell.io",
            accounts: [process.env.PRIVATE_KEY]
        },
    },

    etherscan: {
        apiKey: {
            ropsten: process.env.ROPSTEN_API_KEY,
        },
        customChains: [
            {
                network: "crossbell",
                chainId: 3737,
                urls: {
                    apiURL: "https://scan.crossbell.io/api",
                    browserURL: "https://scan.crossbell.io",
                },
            },
        ],
    },
};