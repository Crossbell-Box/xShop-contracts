/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomiclabs/hardhat-waffle");

module.exports = {
  solidity: "0.8.10",
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/qY5fX9JGza4Id2YX_PuwBl74hvN-3v_8",
        blockNumber: 14390000
      }
    }
  },
};
