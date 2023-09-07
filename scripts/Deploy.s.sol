// SPDX-License-Identifier: MIT
// solhint-disable no-console,ordering
pragma solidity 0.8.18;

import {Deployer} from "./Deployer.sol";
import {DeployConfig} from "./DeployConfig.s.sol";
import {MarketPlace} from "../contracts/MarketPlace.sol";
import {Swap} from "../contracts/Swap.sol";
import {console2 as console} from "forge-std/console2.sol";
import {
    TransparentUpgradeableProxy
} from "../contracts/upgradeability/TransparentUpgradeableProxy.sol";

contract Deploy is Deployer {
    // solhint-disable private-vars-leading-underscore
    DeployConfig internal cfg;

    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    /// @notice The name of the script, used to ensure the right deploy artifacts
    ///         are used.
    function name() public pure override returns (string memory name_) {
        name_ = "Deploy";
    }

    function setUp() public override {
        super.setUp();
        string memory path = string.concat(
            vm.projectRoot(),
            "/deploy-config/",
            deploymentContext,
            ".json"
        );
        cfg = new DeployConfig(path);

        console.log("Deploying from %s", deployScript);
        console.log("Deployment context: %s", deploymentContext);
    }

    /* solhint-disable comprehensive-interface */
    function run() external {
        deployImplementations();

        deployProxies();

        initialize();
    }

    /// @notice Initialize all of the proxies
    function initialize() public {
        initializeMarketPlace();
        initializeSwap();
    }

    /// @notice Deploy all of the proxies
    function deployProxies() public {
        deployProxy("MarketPlace");
        deployProxy("Swap");
    }

    /// @notice Deploy all of the logic contracts
    function deployImplementations() public {
        deployMarketPlace();
        deploySwap();
    }

    function deployProxy(string memory _name) public broadcast returns (address addr_) {
        address logic = mustGetAddress(_stripSemver(_name));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy({
            _logic: logic,
            admin_: cfg.proxyAdminOwner(),
            _data: ""
        });

        // check states
        address admin = address(uint160(uint256(vm.load(address(proxy), OWNER_KEY))));
        require(admin == cfg.proxyAdminOwner(), "proxy admin assert error");

        string memory proxyName = string.concat(_name, "Proxy");
        save(proxyName, address(proxy));
        console.log("%s deployed at %s", proxyName, address(proxy));

        addr_ = address(proxy);
    }

    function deployMarketPlace() public broadcast returns (address addr_) {
        MarketPlace marketPlace = new MarketPlace();

        // check states
        require(marketPlace.wcsb() == address(0), "marketPlace wcsb should be address(0)");
        require(marketPlace.mira() == address(0), "marketPlace mira should be address(0)");

        save("MarketPlace", address(marketPlace));
        console.log("MarketPlace deployed at %s", address(marketPlace));
        addr_ = address(marketPlace);
    }

    function deploySwap() public broadcast returns (address addr_) {
        Swap swap = new Swap();

        // check states
        require(swap.mira() == address(0), "swap mira should be address(0)");
        require(swap.getMinMira() == 0, "swap getMinMira should be 0");
        require(swap.getMinCsb() == 0, "swap getMinCsb should be 0");

        save("Swap", address(swap));
        console.log("Swap deployed at %s", address(swap));
        addr_ = address(swap);
    }

    function initializeMarketPlace() public broadcast {
        MarketPlace marketPlaceProxy = MarketPlace(mustGetAddress("MarketPlaceProxy"));

        marketPlaceProxy.initialize(cfg.wcsb(), cfg.mira(), cfg.admin());

        // check states
        require(marketPlaceProxy.wcsb() == cfg.wcsb(), "marketPlace wcsb error");
        require(marketPlaceProxy.mira() == cfg.mira(), "marketPlace mira error");
        require(
            marketPlaceProxy.hasRole(marketPlaceProxy.ADMIN_ROLE(), cfg.admin()),
            "marketPlace admin error"
        );
    }

    function initializeSwap() public broadcast {
        Swap swapProxy = Swap(mustGetAddress("SwapProxy"));

        swapProxy.initialize(cfg.mira(), cfg.minCsb(), cfg.minMira(), cfg.admin());

        require(swapProxy.mira() == cfg.mira(), "swap mira error");
        require(swapProxy.getMinMira() == cfg.minCsb(), "swap getMinMira error");
        require(swapProxy.getMinCsb() == cfg.minMira(), "swap getMinCsb error");
        require(swapProxy.hasRole(swapProxy.ADMIN_ROLE(), cfg.admin()), "swap admin error");
    }
}
