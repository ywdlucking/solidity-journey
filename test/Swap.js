const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const hre = require("hardhat");

describe("SimpleSwap", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    const amount = hre.ethers.parseEther("10000");

    const [a0,a1, a2] = await hre.ethers.getSigners();

    const t_10 = hre.ethers.parseEther("10");
    const t_60 = hre.ethers.parseEther("60");

    const t1 = await hre.ethers.deployContract("Token1", [amount]);
    const t2 = await hre.ethers.deployContract("Token2", [amount]);
    await t1.waitForDeployment();
    await t2.waitForDeployment();

    await t1.transfer(a1, t_10);
    await t2.transfer(a2, t_60);

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

    return { swap, t1, t2, t1_address, t2_address,a0, a1, a2};
  }

  describe("Deployment", function () {
    it("Should get 50 the ETH", async function () {
      const t_10 = hre.ethers.parseEther("10");
      const t_60 = hre.ethers.parseEther("60");
      const t_100 = hre.ethers.parseEther("100");
      const t_500 = hre.ethers.parseEther("500");
      const { swap, t1, t2, t1_address, t2_address, a0, a1, a2} = await loadFixture(deployOneYearLockFixture);


      const a0_t1 = await t1.balanceOf(a0)
      const a1_t1 = await t1.balanceOf(a1)
      const a2_t1 = await t1.balanceOf(a2)

      console.log(
        `TOKEN1 balanceOf [a0,a1,a2] to [${a0_t1}, ${a1_t1}, ${a2_t1}]`
      );

      const a0_t2 = await t2.balanceOf(a0)
      const a1_t2 = await t2.balanceOf(a1)
      const a2_t2 = await t2.balanceOf(a2)

      console.log(
        `TOKEN2 balanceOf [a0,a1,a2] to [${a0_t2}, ${a1_t2}, ${hre.ethers.formatEther(a2_t2)}]`
      );

      const address = await swap.getAddress();
      await t1.approve(address, t_100)
      await t2.approve(address, t_500)
      await swap.addLiquidity(t_100, t_500);

      const a0_swap = await swap.balanceOf(a0)
      const a1_swap = await swap.balanceOf(a1)
      const a2_swap = await swap.balanceOf(a2)

      console.log(
        `swap balanceOf [a0,a1,a2] to [${hre.ethers.formatEther(a0_swap)}, hre.ethers.formatEther(${a1_swap}), hre.ethers.formatEther(${a2_swap})]`
      );

      await t2.connect(a2).approve(address, t_60)
      await swap.connect(a2).swap(t_60, t2, t_10);
      const a2_balance = await t1.balanceOf(a2)
      expect(parseInt(hre.ethers.formatEther(a2_balance))).to.equal(10);
    });

  });


});
