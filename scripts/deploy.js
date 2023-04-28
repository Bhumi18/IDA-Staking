const hre = require("hardhat");

async function main() {
  const StakingContract = await hre.ethers.getContractFactory(
    "StakingContract"
  );
  const stakingContract = StakingContract.deploy(
    "0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f"
  );
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
