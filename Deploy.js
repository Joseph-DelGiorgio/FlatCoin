const { ethers } = require('hardhat');

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log('Deploying contract...');
  const MyContract = await ethers.getContractFactory('MyContract'); // Replace with your contract name
  const contract = await MyContract.deploy();

  await contract.deployed();

  console.log(`Contract deployed to: ${contract.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
