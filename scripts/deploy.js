const hre = require("hardhat");

async function main() {
  const IDAStaking = await hre.ethers.getContractFactory("IDAStaking");
  const idaStaking = IDAStaking.deploy(
    "0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f"
  );
  await (await idaStaking).deployed();
  const address = (await idaStaking).address;
  console.log(`IDAStaking contract address is ${(await idaStaking).address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
