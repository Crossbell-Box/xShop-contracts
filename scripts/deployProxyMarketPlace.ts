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
    const wcsb = "0x781e5f82f1CfC2bCcBfe0CFC24DB903718D34a2D";
    const mira = "0xb402548B1f3fE59211B19832C5b659bB4d4Abd42";

    const MarketPlace = await ethers.getContractFactory("MarketPlace");
    const marketPlace = await MarketPlace.deploy();
    await marketPlace.deployed();

    const Proxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
    const proxyMarketPlace = await Proxy.deploy(marketPlace.address, proxyOwner, "0x");
    await proxyMarketPlace.deployed();

    await MarketPlace.attach(proxyMarketPlace.address).initialize(wcsb, mira, admin);

    console.log("marketPlace deployed to:", marketPlace.address);
    console.log("proxyMarketPlace deployed to:", proxyMarketPlace.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
