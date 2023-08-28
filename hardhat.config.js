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
  }, 
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  }
};


