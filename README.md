# Hardhat minimal project template

## Installation
Node: 18.15.0

NPM: 9.3.1

Recommended using WSLv2 with LTS Node & NPM version

Deployed & verified contract with Hardhat: [0x443898c58640C34Cf7C58bAE59383C3A9257BdE7](https://sepolia.etherscan.io/address/0x443898c58640C34Cf7C58bAE59383C3A9257BdE7#code)

### Installation dependencies
```bash
npm install
```
### Compile contracts
```bash
npx hardhat compile
```
### Run deploy/migrations
```bash
npx hardhat run scripts/deploy.js --network <network_name>
```
### Verify your contract
```bash
npx hardhat verify --contract "contracts/Token.sol:Token" --network <network_name> <deployed_contract_address>
```
### Verify example
```bash
$ npx hardhat verify --contract "contracts/Token.sol:Token" --network sepolia 0x443898c58640C34Cf7C58bAE59383C3A9257BdE7

Nothing to compile
Successfully submitted source code for contract contracts/Token.sol:Token at 0x443898c58640C34Cf7C58bAE59383C3A9257BdE7 for verification on the block explorer. Waiting for verification result...

Successfully verified contract Token on Etherscan.
https://sepolia.etherscan.io/address/0x443898c58640C34Cf7C58bAE59383C3A9257BdE7#code
```
Read more about verify with arguments:

https://hardhat.org/hardhat-runner/plugins/nomiclabs-hardhat-etherscan
