const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const hre = require("hardhat");

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    const _payees_signer = await hre.ethers.getSigners();
    const _payees = _payees_signer.slice(1,4);
    let _shares = [];
    for (let i=1; i<_payees.length+1;i++) {
      _shares.push(i*10);
    }
    const receiveAmount = hre.ethers.parseEther("10");
    console.log(`_shares: ${_shares}`);
    console.log(`_payees[2].address: ${_payees[2].address}`);
    const pay = await hre.ethers.deployContract("PaymentSplit", [_payees, _shares], {
      value: receiveAmount,
    });

    await pay.waitForDeployment();

    const address = await pay.getAddress();

    console.log(
      `PaymentSplit deployed to ${address}`
    );

    return { pay, _payees};
  }

  describe("Deployment", function () {
    it("Should get 50% the ETH", async function () {
      const { pay, _payees} = await loadFixture(deployOneYearLockFixture);
      await pay.release('0x90F79bf6EB2c4f870365E785982E1f101E93b906');
      const balance  = await hre.ethers.provider.getBalance('0x90F79bf6EB2c4f870365E785982E1f101E93b906');
      const balance_eth  =hre.ethers.formatEther(balance)
      expect(balance_eth).to.equal("10005.0");
    });

  });


});
