// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@std/Test.sol";
import "@std/Script.sol";
import "../MarketPlace.sol";

contract MarketPlaceScript is Script {
    function run() external {
        vm.startBroadcast();

        MarketPlace marketPlace = new MarketPlace();

        vm.stopBroadcast();
    }
}