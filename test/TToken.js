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

const name2 = "TTChina"
const symbol2 = "TTC"
const countryCode2 = 156
// золото металлы 
const resourceIds2 = [1, 2]
const prices2 = [50, 100]
const balances2 = [1000, 2000]

const name3 = "TTIndia"
const symbol3 = "TTI"
const countryCode3 = 356
// золото нефть газ
const resourceIds3 = [1, 3, 4]
const prices3 = [10, 20, 5]
const balances3 = [10, 5, 2]


describe("Creation of TToken", function () {
    async function deployFactoryFixture() {
        const factory = await ethers.deployContract("Factory");
    
        await factory.waitForDeployment;
        return factory
    }
    describe("Deployment", function () {
        it("Deploy Factory check", async function () {
          const factory = await loadFixture(deployFactoryFixture);
          
          expect(
            await factory.getTokenAddressByCountryCode(countryCode1))
              .to.equal(zeroAddress)
          expect(
            await factory.getTokenAddressByCountryCode(countryCode1))
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
    
        /*it("Should assign the total supply of tokens to the owner", async function () {
          const { factory, owner } = await loadFixture(deployFactoryFixture);
          const ownerBalance = await hardhatToken.balanceOf(owner.address);
          expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
        });*/
  
    });
});