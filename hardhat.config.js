require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-docgen');
require('solidity-coverage')

const fs = require('fs');

require('dotenv').config({ path: '.env'});
const PRIVATE_KEY = fs.readFileSync(".secret").toString();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19", 
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    sepolia: {
      url: 'https://sepolia.infura.io/v3/92a117f286914f259e30d3338aad054d',
      accounts: [`0x${PRIVATE_KEY}`], 
      chainId: 11155111
    },
  }, 
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  },
  etherscan: {
    apiKey: "5H4X194822537WKSNVX5SMUWXBXK3GN6DD",
  },
};


