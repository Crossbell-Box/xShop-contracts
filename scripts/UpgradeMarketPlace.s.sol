// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@std/Test.sol";
import "@std/Script.sol";
import "../src/MarketPlace.sol";
import "../src/upgradeability/TransparentUpgradeableProxy.sol";

contract UpgradeMarketPlaceScript is Script {
    address payable marketPlaceProxy = payable(0x648a18765F72bF88A5c01ae914bBcca2e0001F3b); // update marketPlaceProxy address before deployment

    function run() external {
        vm.startBroadcast();

        MarketPlace marketPlace = new MarketPlace();
        TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(marketPlaceProxy);
        proxy.upgradeTo(address(marketPlace));

        vm.stopBroadcast();
    }
}
