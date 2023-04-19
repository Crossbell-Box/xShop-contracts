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

    const MarketPlace = await ethers.getContractFactory("MarketPlace");
    const marketPlace = await MarketPlace.deploy();
    await marketPlace.deployed();

    const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
    const proxyMarketPlace = await Proxy.deploy(marketPlace.address, admin, "0x");
    await proxyMarketPlace.deployed();

    await MarketPlace.attach(proxyMarketPlace.address).initialize(wcsb, mira);

    console.log("marketPlace deployed to:", marketPlace.address);
    console.log("proxyMarketPlace deployed to:", proxyMarketPlace.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
