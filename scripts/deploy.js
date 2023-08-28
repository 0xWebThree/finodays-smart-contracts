async function main() {
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

  const systemAddress = "0x0792157d69D1ee26c927d8A6E6e88D50D4DC039e"

  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const factoryContract = await ethers.getContractFactory("Factory");
  const factory = await factoryContract.deploy();
  
  await factory
    .createTradePair(
      name1,
      symbol1, 
      countryCode1, 
      systemAddress, 
      resourceIds1, 
      prices1, 
      balances1
    )
    await factory
    .createTradePair(
      name2,
      symbol2, 
      countryCode2, 
      systemAddress, 
      resourceIds2, 
      prices2, 
      balances2
    )
  await factory
    .createTradePair(
      name3,
      symbol3, 
      countryCode3, 
      systemAddress, 
      resourceIds3, 
      prices3, 
      balances3
    )
  const tokenFactory = await ethers.getContractFactory("TToken");
  const contractABI = tokenFactory.interface;

  const token1 = new ethers.Contract(
    await factory.getTokenAddressByCountryCode(countryCode1), 
      contractABI, 
      deployer
  );
  const token2 = new ethers.Contract(
    await factory.getTokenAddressByCountryCode(countryCode2), 
      contractABI, 
      deployer
  );
  const token3 = new ethers.Contract(
    await factory.getTokenAddressByCountryCode(countryCode3), 
      contractABI, 
      deployer
  );

  console.log("Deployed factory contract address:", factory.address);
  console.log("Deployed token1 contract address:", token1.address);
  console.log("Deployed token2 contract address:", token2.address);
  console.log("Deployed token3 contract address:", token3.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });