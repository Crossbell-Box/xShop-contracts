// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
    // update these addresses when deploying
    const admin = "0xda2423ceA4f1047556e7a142F81a7ED50e93e160";
    const wcsb = "0xff823B6138089Bea84E8d67fcb68f786e7Feb118";
    const mira = "0xAfB95CC0BD320648B3E8Df6223d9CDD05EbeDC64";
    const minMira = ethers.utils.parseEther("100");
    const minCsb = ethers.utils.parseEther("10");

    const Swap = await ethers.getContractFactory("Swap");
    const swap = await Swap.deploy();
    await swap.deployed();

    const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
    const proxySwap = await Proxy.deploy(swap.address, admin, "0x");
    await proxySwap.deployed();

    await Swap.attach(proxySwap.address).initialize(wcsb, mira, minCsb, minMira);

    console.log("swap deployed to:", swap.address);
    console.log("proxySwap deployed to:", proxySwap.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
