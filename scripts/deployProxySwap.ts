// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    // update these addresses when deploying
    const proxyOwner = "0xc72cE0090718502f08506c4592F18f13094d4CE3";
    const admin = "0x4BCe096F44b90B812420637068dC215C1C3C8B54";
    const mira = "0xb402548B1f3fE59211B19832C5b659bB4d4Abd42";
    const minMira = ethers.utils.parseEther("100");
    const minCsb = ethers.utils.parseEther("0.1");

    const Swap = await ethers.getContractFactory("Swap");
    const swap = await Swap.deploy();
    await swap.deployed();

    const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
    const proxySwap = await Proxy.deploy(swap.address, proxyOwner, "0x");
    await proxySwap.deployed();

    await Swap.attach(proxySwap.address).initialize(mira, minCsb, minMira, admin);

    console.log("swap deployed to:", swap.address);
    console.log("proxySwap deployed to:", proxySwap.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
