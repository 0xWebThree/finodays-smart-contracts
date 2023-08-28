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


describe("TToken", function () {
    async function deployFactoryFixture() {
        const factory = await ethers.deployContract("Factory");
        await factory.waitForDeployment;
        const [_, addrRussia, addrChina, addrIndia, system] = 
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
        await factory.connect(addrIndia)
          .createTradePair(
          name3,
          symbol3, 
          countryCode3, 
          system.address, 
          resourceIds3, 
          prices3, 
          balances3
        )
       
        const tokenFactory = await ethers.getContractFactory("TToken");
        const contractABI = tokenFactory.interface;

        const token1 = new ethers.Contract(
            await factory.getTokenAddressByCountryCode(countryCode1), 
            contractABI, 
            addrRussia
        );
        const token2 = new ethers.Contract(
            await factory.getTokenAddressByCountryCode(countryCode2), 
            contractABI, 
            addrChina
        );
        const token3 = new ethers.Contract(
          await factory.getTokenAddressByCountryCode(countryCode3), 
          contractABI, 
          addrIndia
       );
        return { factory, token1, token2, token3, addrRussia, addrChina, addrIndia, system }
    }
    describe("Basic functionality", function () {
        it("Deploy & initial params check", async function () {
          const { 
            factory, token1, 
            token2, token3, 
            addrRussia, addrChina, 
            addrIndia, system 
          } = await loadFixture(deployFactoryFixture);

          expect(await token1.getCountryCode()).to.equal(countryCode1)
          expect(await token1.getFactoryAddress()).to.equal(factory.address)
          expect(await token1.getCompanyAddressById(0)).to.equal(token1.address)
          expect((await token1.getAllCompanies()).length).to.equal(1)
          expect(await token1.getNomenclatureResourceBalance(1)).to.equal(5)
          expect(await token1.getNomenclatureResourceBalance(3)).to.equal(10)
          expect(await token1.getNomenclatureResourceBalance(4)).to.equal(30)
          expect(await token1.getNomenclatureResourceBalance(5)).to.equal(40)
        });

        it("Add company, top up balance, withdraw, transfer ttoken", async function () {
          const { 
            factory, token1, 
            token2, token3, 
            addrRussia, addrChina, 
            addrIndia, system 
          } = await loadFixture(deployFactoryFixture);
          const russia1 = await ethers.getSigner(10)
          const russia2 = await ethers.getSigner(11)
          
          //Company add
          
          await token1.connect(russia1).addCompany()
          await expect(
            token1.connect(russia1).addCompany()
          ).to.be.revertedWith('TToken: company already exists');

          expect(await token1.getCompanyAddressById(0)).to.equal(token1.address)
          expect(await token1.getCompanyAddressById(1)).to.equal(russia1.address)

          await token1.connect(russia2).addCompany()
          await expect(
            token1.connect(russia2).addCompany()
          ).to.be.revertedWith('TToken: company already exists');
          expect(await token1.getCompanyAddressById(2)).to.equal(russia2.address)
          
          // TOP UP & WITHDRAW company balance
          // 100 рублей платит, курс по золоту (20-rate)
          await token1.connect(russia1).topUpBalance(100, resourceIds1[0])
          expect(await token1.balanceOf(russia1.address)).to.equal(prices1[0]*100)

          await token1.connect(russia1).topUpBalance(40, resourceIds1[1])

          console.log(await token1.balanceOf(russia1.address))
          expect(await token1.balanceOf(russia1.address)).to.equal(prices1[1]*40 + prices1[0]*100)

          console.log("Operation2: ", await token1.getOperationsInArrayByAddress(russia1.address))
          
          // balance = 3200, 
          await token1.connect(russia1).withdraw(1000, resourceIds1[0])

          // tokens to withdraw sends back to central bank
          expect(await token1.balanceOf(token1.address)).to.equal(1000)

          expect(await token1.getCompanyId(russia1.address)).to.equal(1)
          expect(await token1.balanceOf(russia1.address)).to.equal(3200-1000)

          await token1.connect(russia1).withdraw(1000, resourceIds1[0])
          expect(await token1.balanceOf(russia1.address)).to.equal(3200-1000 - 1000)

          // TRANSFER, TRANSFER_FROM, APPROVE tokens
          await token1.connect(russia1).transfer(russia2.address, 1000, 0, 0)
          expect(await token1.balanceOf(russia1.address)).to.equal(200)
          expect(await token1.balanceOf(russia2.address)).to.equal(1000)

          await token1.connect(russia1).transfer(russia2.address, 100, 0, 0)
          expect(await token1.balanceOf(russia1.address)).to.equal(200-100)
          expect(await token1.balanceOf(russia2.address)).to.equal(1000+100)

          await token1.connect(russia1).approve(russia2.address, 100)
          await token1.connect(russia2).transferFrom(
            russia1.address, 
            russia2.address, 
            0, 
            0, 
            100
          )
          expect(await token1.balanceOf(russia1.address)).to.equal(200-100-100)
          expect(await token1.balanceOf(russia2.address)).to.equal(1000+100+100)

        });

        it("TopUpBalance & Withdraw through another token", async function () {
          const { 
            factory, token1, 
            token2, token3, 
            addrRussia, addrChina, 
            addrIndia, system 
          } = await loadFixture(deployFactoryFixture);
          const russia1 = await ethers.getSigner(10)
          const china1 = await ethers.getSigner(11)

          await token1.connect(russia1).addCompany()
          await token2.connect(china1).addCompany()

          await token1.connect(russia1).topUpBalance(500, resourceIds1[0])
          await token2.connect(china1).topUpBalance(700, resourceIds1[0])

          // сделать резерв с другим токеном у банка рф, симуляция 
          await token2.connect(china1).transfer(token1.address, 700, 0, 0);
          expect(await token2.balanceOf(token1.address)).to.equal(700)
          
          // пополнение через другой токен (у цб есть) на 100 рублей по курсу рф
          await token1.connect(russia1)
            .topUpBalanceWithAnotherToken(token2.address, 100, resourceIds1[0])

          // 20*100 > 700 => переведется на 700. частичный минт, тк недостаточно средств
          expect(await token2.balanceOf(russia1.address)).to.equal(700)

        });
    });
  });



