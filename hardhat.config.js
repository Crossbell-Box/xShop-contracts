/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require("@nomiclabs/hardhat-waffle");

module.exports = {
  solidity: "0.8.10",
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-rinkeby.alchemyapi.io/v2/7Fg57KefoWIvDxCVLMEKwYgLvuXZ43rH",
      }
    }
  },
};
