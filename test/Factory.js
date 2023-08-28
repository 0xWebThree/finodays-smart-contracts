const { expect } = require("chai");
const {
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");

const zeroAddress = "0x0000000000000000000000000000000000000000"
const name1 = "TTRussia"
const symbol1 = "TTR"
const countryCode1 = 643
// золото нефть газ лес
const resourceIds1 = [1, 3, 4, 5]
const prices1 = [20, 30, 10, 5]
const balances1 = [5, 10, 30, 40]

describe("Factory", function () {
    async function deployFactoryFixture() {
        const factory = await ethers.deployContract("Factory");
    
        await factory.waitForDeployment;
        return factory
    }
    describe("Funcionality", function () {
        it("Deploy check", async function () {
          const factory = await loadFixture(deployFactoryFixture);
          
          expect(
            await factory.getTokenAddressByCountryCode(countryCode1))
              .to.equal(zeroAddress)
          expect(
            await factory.getOracleAddressByCountryCode(countryCode1))
              .to.equal(zeroAddress)
        });

        it("TToken & Oracle creation", async function () {
          const factory = await loadFixture(deployFactoryFixture);
          const [owner, addrRussia, addrChina, addrIndia, system] = 
            await ethers.getSigners();

          const tradePair1 = await factory.connect(addrRussia)
            .createTradePair(
              name1,
              symbol1, 
              countryCode1, 
              system.address, 
              resourceIds1, 
              prices1, 
              balances1
            )
          const token1 = await factory.getTokenAddressByCountryCode(countryCode1)
          const oracle1 = await factory.getOracleAddressByCountryCode(countryCode1)

          await expect(tradePair1)
            .to.emit(factory, "TradePairCreated")
            .withArgs(countryCode1, token1, oracle1);
              
          console.log(token1, "\n", oracle1)
        });
    });
});
