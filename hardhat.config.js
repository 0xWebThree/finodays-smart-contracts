require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-docgen');

const fs = require('fs');

require('dotenv').config({ path: '.env'});
const PRIVATE_KEY = fs.readFileSync(".secret").toString();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19", 
  networks: {
  }, 
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  }
};


