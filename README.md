# Solidity smart contracts & Hardhat

## Generate docs
### With compilation
```bash
npx hardhat docgen
```
### Without compilation
```bash
npx hardhat docgen --no-compile
```

## Software requirements
Checked on:
  Node: 16.16.0
  NPM: 8.11.0

Recommended using WSLv2 with LTS Node & NPM version

## Installation 
```bash
npm install
```

## Compile contracts
```bash
npx hardhat compile
```

## Run deploy/migrations
```bash
npx hardhat run scripts/deploy.js --network <network_name>
```

## Run tests
```bash
npx hardhat test
```

## Verify contracts
```bash
npx hardhat verify --constructor-args scripts/arguments.js --network sepolia {contractAddress}
```

