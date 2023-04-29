const hre = require("hardhat");

async function main() {
  const StakingContract = await hre.ethers.getContractFactory(
    "StakingContract"
  );
  const stakingContract = StakingContract.deploy();
  await (await stakingContract).deployed();
  const address = (await stakingContract).address;
  console.log(
    `stakingContract contract address is ${(await stakingContract).address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
