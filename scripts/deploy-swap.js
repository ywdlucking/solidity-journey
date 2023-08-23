// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const _payees = await hre.ethers.getSigners();
  console.log(`_payees : ${_payees}`)
  // let _shares = [];
  // for (let i=1; i<_payees.length+1;i++) {
  //   _shares.push(i*10);
  // }
  // console.log(`_shares: ${_shares}`)

  const amount = hre.ethers.parseEther("10000");

  const t1 = await hre.ethers.deployContract("Token1", [amount]);
  const t2 = await hre.ethers.deployContract("Token2", [amount]);
  await t1.waitForDeployment();
  await t2.waitForDeployment();
  const t1_address = await t1.getAddress();
  console.log(
    `Token1 deployed to ${t1_address}`
  );
  const t2_address = await t2.getAddress();
  console.log(
    `Token2 deployed to ${t2_address}`
  );
  const swap = await hre.ethers.deployContract("SimpleSwap", [t1_address, t2_address]);

  await swap.waitForDeployment();

  const address = await swap.getAddress();

  console.log(
    `Swap deployed to ${address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
