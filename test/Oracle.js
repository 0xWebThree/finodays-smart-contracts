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

/*
describe("Oracle", function () {
    async function deployOracleFixture() {
        const factory = await ethers.deployContract("Factory")
    
        await factory.waitForDeployment;
        const [_, addrRussia, addrChina, system] = 
            await ethers.getSigners()

        await factory.connect(addrRussia)
          .createTradePair(
          name1,
          symbol1, 
          countryCode1, 
          system.address, 
          resourceIds1, 
          prices1, 
          balances1
        )
        await factory.connect(addrChina)
          .createTradePair(
          name2,
          symbol2, 
          countryCode2, 
          system.address, 
          resourceIds2, 
          prices2, 
          balances2
        )
       
        const oracleFactory = await ethers.getContractFactory("Oracle");
        const contractABI = oracleFactory.interface;

        const oracle1 = new ethers.Contract(
            await factory.getOracleAddressByCountryCode(countryCode1), 
            contractABI, 
            addrRussia
        );
        const oracle2 = new ethers.Contract(
            await factory.getOracleAddressByCountryCode(countryCode2), 
            contractABI, 
            addrChina
        );
        
        return { factory, oracle1, oracle2, addrRussia, addrChina, system }
    }
    describe("Funcionality", function () {
        it("Deploy & initial params check", async function () {
          const { factory, oracle1, oracle2, addrRussia, addrChina, system } = 
            await loadFixture(deployOracleFixture)
          
          expect(await oracle1.decimals()).to.equal(1)
          expect(await oracle2.decimals()).to.equal(1)

          await expect(
            oracle1.getProductRateById(8)
          ).to.be.revertedWith('Oracle: unappropriate productId');
          await expect(
            oracle1.getProductRateById(2)
          ).to.be.revertedWith('Oracle: unappropriate productId');
          await expect(
            oracle2.getProductRateById(8)
          ).to.be.revertedWith('Oracle: unappropriate productId');
          await expect(
            oracle2.getProductRateById(3)
          ).to.be.revertedWith('Oracle: unappropriate productId');
          await expect(
            oracle2.getProductRateById(4)
          ).to.be.revertedWith('Oracle: unappropriate productId');
          await expect(
            oracle2.getProductRateById(5)
          ).to.be.revertedWith('Oracle: unappropriate productId');
          
          expect(await oracle1.getProductRateById(1)).to.equal(20)
          expect(await oracle1.getProductRateById(3)).to.equal(30)
          expect(await oracle1.getProductRateById(4)).to.equal(10)
          expect(await oracle1.getProductRateById(5)).to.equal(5)

          expect(await oracle2.getProductRateById(1)).to.equal(50)
          expect(await oracle2.getProductRateById(2)).to.equal(100)
        });

        it("setRate & getRate", async function () {
          const { factory, oracle1, oracle2, addrRussia, addrChina, system } = 
            await loadFixture(deployOracleFixture)

            await expect(
              oracle1.setProductRate(3, 100)
            ).to.be.revertedWith('Ownable: caller is not the owner');
            expect(await oracle1.getProductRateById(3)).to.equal(30)
            await oracle1.connect(system).setProductRate(3, 100)
            expect(await oracle1.getProductRateById(3)).to.equal(100)

            await expect(
                oracle2.setProductRate(2, 100)
            ).to.be.revertedWith('Ownable: caller is not the owner');
            expect(await oracle2.getProductRateById(2)).to.equal(100)
            await oracle2.connect(system).setProductRate(2, 200)
            expect(await oracle2.getProductRateById(2)).to.equal(200)
        });
    });
});
*/