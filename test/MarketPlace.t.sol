// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.18;

import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "../contracts/MarketPlace.sol";
import {DataTypes} from "../contracts/libraries/DataTypes.sol";
import {Events} from "../contracts/libraries/Events.sol";
import {MiraToken} from "../contracts/mocks/MiraToken.sol";
import {WCSB} from "../contracts/mocks/WCSB.sol";
import {NFT, NFT1155} from "../contracts/mocks/NFT.sol";
import {EmitExpecter} from "./EmitExpecter.sol";
import {
    TransparentUpgradeableProxy
} from "../contracts/upgradeability/TransparentUpgradeableProxy.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract MarketPlaceTest is Test, EmitExpecter {
    TransparentUpgradeableProxy public proxyMarketPlace;
    MarketPlace market;
    WCSB wcsb;
    MiraToken mira;
    NFT nft;
    NFT1155 nft1155;

    // ask accounts
    address public constant alice = address(0x1111);
    // bid accounts
    address public constant bob = address(0x2222);

    address public constant admin = address(0x3333);
    address public constant proxyOwner = address(0x4444);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant MAX_ROYALTY = 10000;
    uint256 public constant INITIAL_MIRA_BALANCE = 100 ether;
    uint256 public constant INITIAL_CSB_BALANCE = 100 ether;

    event Paused(address account);
    event Unpaused(address account);

    function setUp() public {
        // deploy erc1820
        vm.etch(
            address(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24),
            bytes( // solhint-disable-next-line max-line-length
                hex"608060405234801561001057600080fd5b50600436106100a5576000357c010000000000000000000000000000000000000000000000000000000090048063a41e7d5111610078578063a41e7d51146101d4578063aabbb8ca1461020a578063b705676514610236578063f712f3e814610280576100a5565b806329965a1d146100aa5780633d584063146100e25780635df8122f1461012457806365ba36c114610152575b600080fd5b6100e0600480360360608110156100c057600080fd5b50600160a060020a038135811691602081013591604090910135166102b6565b005b610108600480360360208110156100f857600080fd5b5035600160a060020a0316610570565b60408051600160a060020a039092168252519081900360200190f35b6100e06004803603604081101561013a57600080fd5b50600160a060020a03813581169160200135166105bc565b6101c26004803603602081101561016857600080fd5b81019060208101813564010000000081111561018357600080fd5b82018360208201111561019557600080fd5b803590602001918460018302840111640100000000831117156101b757600080fd5b5090925090506106b3565b60408051918252519081900360200190f35b6100e0600480360360408110156101ea57600080fd5b508035600160a060020a03169060200135600160e060020a0319166106ee565b6101086004803603604081101561022057600080fd5b50600160a060020a038135169060200135610778565b61026c6004803603604081101561024c57600080fd5b508035600160a060020a03169060200135600160e060020a0319166107ef565b604080519115158252519081900360200190f35b61026c6004803603604081101561029657600080fd5b508035600160a060020a03169060200135600160e060020a0319166108aa565b6000600160a060020a038416156102cd57836102cf565b335b9050336102db82610570565b600160a060020a031614610339576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b6103428361092a565b15610397576040805160e560020a62461bcd02815260206004820152601a60248201527f4d757374206e6f7420626520616e204552433136352068617368000000000000604482015290519081900360640190fd5b600160a060020a038216158015906103b85750600160a060020a0382163314155b156104ff5760405160200180807f455243313832305f4143434550545f4d4147494300000000000000000000000081525060140190506040516020818303038152906040528051906020012082600160a060020a031663249cb3fa85846040518363ffffffff167c01000000000000000000000000000000000000000000000000000000000281526004018083815260200182600160a060020a0316600160a060020a031681526020019250505060206040518083038186803b15801561047e57600080fd5b505afa158015610492573d6000803e3d6000fd5b505050506040513d60208110156104a857600080fd5b5051146104ff576040805160e560020a62461bcd02815260206004820181905260248201527f446f6573206e6f7420696d706c656d656e742074686520696e74657266616365604482015290519081900360640190fd5b600160a060020a03818116600081815260208181526040808320888452909152808220805473ffffffffffffffffffffffffffffffffffffffff19169487169485179055518692917f93baa6efbd2244243bfee6ce4cfdd1d04fc4c0e9a786abd3a41313bd352db15391a450505050565b600160a060020a03818116600090815260016020526040812054909116151561059a5750806105b7565b50600160a060020a03808216600090815260016020526040902054165b919050565b336105c683610570565b600160a060020a031614610624576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b81600160a060020a031681600160a060020a0316146106435780610646565b60005b600160a060020a03838116600081815260016020526040808220805473ffffffffffffffffffffffffffffffffffffffff19169585169590951790945592519184169290917f605c2dbf762e5f7d60a546d42e7205dcb1b011ebc62a61736a57c9089d3a43509190a35050565b600082826040516020018083838082843780830192505050925050506040516020818303038152906040528051906020012090505b92915050565b6106f882826107ef565b610703576000610705565b815b600160a060020a03928316600081815260208181526040808320600160e060020a031996909616808452958252808320805473ffffffffffffffffffffffffffffffffffffffff19169590971694909417909555908152600284528181209281529190925220805460ff19166001179055565b600080600160a060020a038416156107905783610792565b335b905061079d8361092a565b156107c357826107ad82826108aa565b6107b85760006107ba565b815b925050506106e8565b600160a060020a0390811660009081526020818152604080832086845290915290205416905092915050565b6000808061081d857f01ffc9a70000000000000000000000000000000000000000000000000000000061094c565b909250905081158061082d575080155b1561083d576000925050506106e8565b61084f85600160e060020a031961094c565b909250905081158061086057508015155b15610870576000925050506106e8565b61087a858561094c565b909250905060018214801561088f5750806001145b1561089f576001925050506106e8565b506000949350505050565b600160a060020a0382166000908152600260209081526040808320600160e060020a03198516845290915281205460ff1615156108f2576108eb83836107ef565b90506106e8565b50600160a060020a03808316600081815260208181526040808320600160e060020a0319871684529091529020549091161492915050565b7bffffffffffffffffffffffffffffffffffffffffffffffffffffffff161590565b6040517f01ffc9a7000000000000000000000000000000000000000000000000000000008082526004820183905260009182919060208160248189617530fa90519096909550935050505056fea165627a7a72305820377f4a2d4301ede9949f163f319021a6e9c687c292a5e2b2c4734c126b524e6c0029"
            )
        );

        wcsb = new WCSB();
        mira = new MiraToken("MIRA", "MIRA", address(this));
        nft = new NFT("NFt", "NFT");
        nft1155 = new NFT1155();

        market = new MarketPlace();
        proxyMarketPlace = new TransparentUpgradeableProxy(address(market), proxyOwner, "");
        market = MarketPlace(address(proxyMarketPlace));
        market.initialize(address(wcsb), address(mira), admin);

        nft.mint(alice);
        nft1155.mint(alice);
        mira.mint(bob, INITIAL_MIRA_BALANCE);
        vm.deal(bob, INITIAL_CSB_BALANCE);
    }

    function testSetupStates() public {
        assertEq(address(market.wcsb()), address(wcsb));
        assertEq(address(market.mira()), address(mira));
    }

    function testInitFail() public {
        // reinit
        vm.expectRevert(abi.encodePacked("Initializable: contract is already initialized"));
        market.initialize(address(0x4), address(0x4), admin);
    }

    function testPause() public {
        // expect events
        expectEmit(CheckAll);
        emit Paused(admin);
        vm.prank(admin);
        market.pause();

        // check paused
        assertEq(market.paused(), true);
    }

    function testPauseFail() public {
        // case 1: caller is not admin
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(this)),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        market.pause();
        // check paused
        assertEq(market.paused(), false);

        // pause gateway
        vm.startPrank(admin);
        market.pause();
        // case 2: gateway has been paused
        vm.expectRevert(abi.encodePacked("Pausable: paused"));
        market.pause();
        vm.stopPrank();
    }

    function testUnpause() public {
        vm.prank(admin);
        market.pause();
        // check paused
        assertEq(market.paused(), true);

        // expect events
        expectEmit(CheckAll);
        emit Unpaused(admin);
        vm.prank(admin);
        market.unpause();

        // check paused
        assertEq(market.paused(), false);
    }

    function testUnpauseFail() public {
        // case 1: gateway not paused
        vm.expectRevert(abi.encodePacked("Pausable: not paused"));
        market.unpause();
        // check paused
        assertEq(market.paused(), false);

        // case 2: caller is not admin
        vm.prank(admin);
        market.pause();
        // check paused
        assertEq(market.paused(), true);
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(address(this)),
                " is missing role ",
                Strings.toHexString(uint256(ADMIN_ROLE), 32)
            )
        );
        market.unpause();
        // check paused
        assertEq(market.paused(), true);
    }

    function testAskFail() public {
        uint256 expiration = block.timestamp + 10;

        vm.expectRevert(abi.encodePacked("InvalidPayToken"));
        market.ask(address(nft), 1, address(0x567), 1, expiration);

        vm.expectRevert(abi.encodePacked("InvalidDeadline"));
        market.ask(address(nft), 1, address(wcsb), 1, block.timestamp);

        vm.expectRevert(abi.encodePacked("InvalidPrice"));
        market.ask(address(nft), 1, address(wcsb), 0, expiration);

        vm.expectRevert(abi.encodePacked("TokenNotERC721"));
        market.ask(address(nft1155), 1, address(wcsb), 1, expiration);

        // not erc721
        vm.expectRevert();
        market.ask(address(0x1234), 1, address(wcsb), 1, expiration);

        vm.expectRevert(abi.encodePacked("NotERC721TokenOwner"));
        vm.prank(bob);
        market.ask(address(nft), 1, address(wcsb), 1, expiration);

        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, expiration);
        vm.expectRevert(abi.encodePacked("AskExists"));
        market.ask(address(nft), 1, address(wcsb), 1, expiration);
        vm.stopPrank();
    }

    function testAsk() public {
        uint256 expiration = block.timestamp + 10;

        expectEmit(CheckAll);
        // The event we expect
        emit Events.AskCreated(alice, address(nft), 1, address(wcsb), 1, expiration);
        // The event we get
        vm.prank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, expiration);

        DataTypes.Order memory order = market.getAskOrder(address(nft), 1, alice);
        // check ask order
        _matchOrder(order, alice, address(nft), 1, address(wcsb), 1, expiration);
    }

    function testBidFail() public {
        uint256 expiration = block.timestamp + 10;

        vm.expectRevert(abi.encodePacked("InvalidPayToken"));
        market.bid(address(nft), 1, address(0x567), 1, expiration);

        vm.expectRevert(abi.encodePacked("InvalidDeadline"));
        market.bid(address(nft), 1, address(wcsb), 1, block.timestamp);

        vm.expectRevert(abi.encodePacked("InvalidPrice"));
        market.bid(address(nft), 1, address(wcsb), 0, expiration);

        vm.expectRevert(abi.encodePacked("TokenNotERC721"));
        market.bid(address(nft1155), 1, address(wcsb), 1, 100);

        // not erc721
        vm.expectRevert();
        market.bid(address(0x1234), 1, address(wcsb), 1, expiration);

        vm.startPrank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, expiration);
        vm.expectRevert(abi.encodePacked("BidExists"));
        market.bid(address(nft), 1, address(wcsb), 1, expiration);
        vm.stopPrank();
    }

    function testBid() public {
        uint256 expiration = block.timestamp + 10;

        expectEmit(CheckAll);
        // The event we expect
        emit Events.BidCreated(bob, address(nft), 1, address(wcsb), 1, expiration);
        // The event we get
        vm.prank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, expiration);

        // check bid order
        DataTypes.Order memory order = market.getBidOrder(address(nft), 1, bob);
        // check ask order
        _matchOrder(order, bob, address(nft), 1, address(wcsb), 1, expiration);
    }

    function testCancelBid() public {
        uint256 expiration = block.timestamp + 100;

        vm.startPrank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, expiration);

        expectEmit(CheckAll);
        // The event we expect
        emit Events.BidCanceled(bob, address(nft), 1);
        // The event we get
        market.cancelBid(address(nft), 1);
        vm.stopPrank();

        // check bid order
        _assertEmptyOrder(address(nft), 1, bob, false);
    }

    function testCancelBidFail() public {
        vm.startPrank(bob);

        vm.expectRevert(abi.encodePacked("BidNotExists"));
        market.cancelBid(address(nft), 1);

        vm.expectRevert(abi.encodePacked("BidNotExists"));
        market.cancelBid(address(nft), 1000);

        vm.expectRevert(abi.encodePacked("BidNotExists"));
        market.cancelBid(address(nft1155), 1);

        vm.expectRevert(abi.encodePacked("BidNotExists"));
        market.cancelBid(address(0x1234), 1);

        vm.stopPrank();
    }

    function testUpdateBid() public {
        uint256 expiration = block.timestamp + 100;

        vm.startPrank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, 10);

        expectEmit(CheckAll);
        // The event we expect
        emit Events.BidUpdated(bob, address(nft), 1, address(wcsb), 100, expiration);
        // The event we get
        market.updateBid(address(nft), 1, address(wcsb), 100, expiration);

        DataTypes.Order memory order = market.getBidOrder(address(nft), 1, bob);
        // check bid order
        _matchOrder(order, bob, address(nft), 1, address(wcsb), 100, expiration);
        vm.stopPrank();
    }

    function testUpdateBidFail() public {
        // nft contract not exists
        vm.expectRevert(abi.encodePacked("BidNotExists"));
        market.updateBid(address(0x678), 1, address(wcsb), 2, 1);

        // token id not exists
        vm.expectRevert(abi.encodePacked("BidNotExists"));
        market.updateBid(address(nft), 1000, address(wcsb), 2, 1);

        // owner has no orders
        vm.prank(bob);
        vm.expectRevert(abi.encodePacked("BidNotExists"));
        market.updateBid(address(nft), 1, address(wcsb), 2, 1);

        vm.startPrank(alice);
        market.bid(address(nft), 1, address(wcsb), 1, 100);

        // invalid deadline
        vm.expectRevert(abi.encodePacked("InvalidDeadline"));
        market.updateBid(address(nft), 1, address(wcsb), 2, 1);

        // invalid pay token
        vm.expectRevert(abi.encodePacked("InvalidPayToken"));
        market.updateBid(address(nft), 1, address(0x1111), 2, block.timestamp + 1);

        // invalid price
        vm.expectRevert(abi.encodePacked("InvalidPrice"));
        market.updateBid(address(nft), 1, address(wcsb), 0, block.timestamp + 1);
        vm.stopPrank();
    }

    function testUpdateAskFail() public {
        uint256 expiration = block.timestamp + 100;

        // not owner(actually the same as notExisted)
        vm.prank(bob);
        vm.expectRevert(abi.encodePacked("AskNotExists"));
        market.updateAsk(address(nft), 1, address(wcsb), 1, expiration);

        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, expiration);

        // not existed
        vm.expectRevert(abi.encodePacked("AskNotExists"));
        market.updateAsk(address(nft), 2, address(wcsb), 1, expiration);
        vm.expectRevert(abi.encodePacked("AskNotExists"));
        market.updateAsk(address(nft1155), 1, address(wcsb), 1, expiration);

        // invalid pay token
        vm.expectRevert(abi.encodePacked("InvalidPayToken"));
        market.updateAsk(address(nft), 1, address(0x567), 1, expiration);

        // invalid deadline
        vm.expectRevert(abi.encodePacked("InvalidDeadline"));
        market.updateAsk(address(nft), 1, address(wcsb), 1, block.timestamp);

        // invalid price
        vm.expectRevert(abi.encodePacked("InvalidPrice"));
        market.updateAsk(address(nft), 1, address(wcsb), 0, expiration);
        vm.stopPrank();
    }

    function testUpdateAsk() public {
        uint256 expiration = block.timestamp + 100;

        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 10);

        expectEmit(CheckAll);
        // The event we expect
        emit Events.AskUpdated(alice, address(nft), 1, address(wcsb), 100, expiration);
        // The event we get
        market.updateAsk(address(nft), 1, address(wcsb), 100, expiration);

        DataTypes.Order memory order = market.getAskOrder(address(nft), 1, alice);
        // check ask order
        _matchOrder(order, alice, address(nft), 1, address(wcsb), 100, expiration);
        vm.stopPrank();
    }

    function testCancelAskFail() public {
        vm.startPrank(alice);

        // AskNotExists
        vm.expectRevert(abi.encodePacked("AskNotExists"));
        market.cancelAsk(address(nft), 1);

        vm.expectRevert(abi.encodePacked("AskNotExists"));
        market.cancelAsk(address(nft), 1000);

        vm.expectRevert(abi.encodePacked("AskNotExists"));
        market.cancelAsk(address(nft1155), 1);

        vm.expectRevert(abi.encodePacked("AskNotExists"));
        market.cancelAsk(address(0x1234), 1);

        vm.stopPrank();
    }

    function testCancelAsk() public {
        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 100);

        expectEmit(CheckAll);
        emit Events.AskCanceled(alice, address(nft), 1);
        market.cancelAsk(address(nft), 1);
        vm.stopPrank();

        // check ask order
        _assertEmptyOrder(address(nft), 1, alice, true);
    }

    function testAcceptAskWithCSB() public {
        uint256 price = 100;

        //  create ask order
        vm.startPrank(alice);
        nft.setApprovalForAll(address(market), true);
        market.ask(address(nft), 1, address(wcsb), price, block.timestamp + 10);
        vm.stopPrank();

        vm.deal(bob, 1 ether);
        // expect event
        expectEmit(CheckAll);
        emit Events.AskMatched(alice, address(nft), 1, bob, address(wcsb), price, address(0x0), 0);
        vm.prank(bob);
        market.acceptAsk{value: price}(address(nft), 1, alice);

        // check csb balance
        assertEq(alice.balance, price);
        assertEq(bob.balance, 1 ether - price);
        // check ask order
        _assertEmptyOrder(address(nft), 1, alice, true);
    }

    function testAcceptAskWithERC20(uint256 price) public {
        vm.assume(price > 1);
        vm.assume(price < 10 ether);

        address nftAddress = address(nft);
        uint256 tokenId = 1;
        address payToken = address(mira);
        uint256 deadline = block.timestamp + 10;

        //  create ask order
        vm.startPrank(alice);
        nft.setApprovalForAll(address(market), true);
        market.ask(nftAddress, tokenId, payToken, price, deadline);
        vm.stopPrank();

        // prepare mira
        vm.prank(bob);
        mira.approve(address(market), price);

        // expect event
        expectEmit(CheckAll);
        emit Events.AskMatched(alice, nftAddress, tokenId, bob, payToken, price, address(0x0), 0);
        // accept ask
        vm.prank(bob);
        market.acceptAsk(nftAddress, tokenId, alice);

        // check csb balance
        assertEq(mira.balanceOf(alice), price);
        assertEq(mira.balanceOf(bob), INITIAL_MIRA_BALANCE - price);

        // check ask order
        _assertEmptyOrder(nftAddress, tokenId, alice, true);
    }

    function testAcceptAskWithCSBWithRoyalty(uint256 price, uint96 percentage) public {
        vm.assume(price > 100);
        vm.assume(price < 10 ether);
        vm.assume(percentage <= MAX_ROYALTY);

        address nftAddress = address(nft);
        uint256 tokenId = 1;
        address payToken = address(wcsb);
        uint256 deadline = block.timestamp + 10;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price * percentage) / 10000;

        //  create ask order
        vm.startPrank(alice);
        nft.setDefaultRoyalty(royaltyReceiver, percentage);
        market.ask(nftAddress, tokenId, payToken, price, deadline);
        // prepare
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // expect event
        expectEmit(CheckAll);
        emit Events.AskMatched(
            alice,
            nftAddress,
            tokenId,
            bob,
            payToken,
            price,
            royaltyReceiver,
            feeAmount
        );
        // accept ask
        vm.prank(bob);
        market.acceptAsk{value: price}(nftAddress, 1, alice);

        // check csb balance
        assertEq(alice.balance, price - feeAmount);
        assertEq(royaltyReceiver.balance, feeAmount);
        assertEq(bob.balance, INITIAL_CSB_BALANCE - price);

        // check ask order
        _assertEmptyOrder(nftAddress, tokenId, alice, true);
    }

    function testAcceptAskWithWCSBWithRoyalty(uint96 percentage) public {
        vm.assume(percentage <= MAX_ROYALTY);

        uint256 price = 1000;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price * percentage) / 10000;

        //  create ask order
        vm.startPrank(alice);
        nft.setDefaultRoyalty(royaltyReceiver, percentage);
        market.ask(address(nft), 1, address(wcsb), price, block.timestamp + 10);
        // prepare
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // expect event
        expectEmit(CheckAll);
        emit Events.AskMatched(
            alice,
            address(nft),
            1,
            bob,
            address(wcsb),
            price,
            royaltyReceiver,
            feeAmount
        );
        // accept ask
        vm.prank(bob);
        market.acceptAsk{value: price}(address(nft), 1, alice);

        // check wcsb balance
        assertEq(alice.balance, price - feeAmount);
        assertEq(royaltyReceiver.balance, feeAmount);
        assertEq(bob.balance, INITIAL_CSB_BALANCE - price);

        // check ask order
        _assertEmptyOrder(address(nft), 1, alice, true);
    }

    function testAcceptAskWithERC777SendHook(uint256 price, uint96 percentage) public {
        vm.assume(price > 1);
        vm.assume(price < 10 ether);
        vm.assume(percentage <= MAX_ROYALTY);

        address nftAddress = address(nft);
        uint256 tokenId = 1;
        address payToken = address(mira);
        uint256 deadline = block.timestamp + 10;

        //  create ask order
        vm.startPrank(alice);
        market.ask(nftAddress, tokenId, payToken, price, deadline);
        // prepare
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // expect event
        expectEmit(CheckAll);
        emit Events.AskMatched(alice, nftAddress, tokenId, bob, payToken, price, address(0), 0);
        // accept ask
        vm.prank(bob);
        mira.send(address(market), price, abi.encode(nftAddress, tokenId, alice));

        // check csb balance
        assertEq(mira.balanceOf(alice), price);
        assertEq(mira.balanceOf(bob), INITIAL_MIRA_BALANCE - price);

        // check ask order
        _assertEmptyOrder(nftAddress, tokenId, alice, true);
    }

    function testAcceptAskWithRoraltyWithERC777SendHook(uint256 price, uint96 percentage) public {
        vm.assume(price > 1);
        vm.assume(price < 10 ether);
        vm.assume(percentage <= MAX_ROYALTY);

        address nftAddress = address(nft);
        uint256 tokenId = 1;
        address payToken = address(mira);
        uint256 deadline = block.timestamp + 10;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price * percentage) / 10000;

        //  create ask order
        vm.startPrank(alice);
        nft.setDefaultRoyalty(royaltyReceiver, percentage);
        market.ask(nftAddress, tokenId, payToken, price, deadline);
        // prepare
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // expect event
        expectEmit(CheckAll);
        emit Events.AskMatched(
            alice,
            nftAddress,
            tokenId,
            bob,
            payToken,
            price,
            royaltyReceiver,
            feeAmount
        );
        // accept ask
        vm.prank(bob);
        mira.send(address(market), price, abi.encode(nftAddress, tokenId, alice));

        // check csb balance
        assertEq(mira.balanceOf(alice), price - feeAmount);
        assertEq(mira.balanceOf(royaltyReceiver), feeAmount);
        assertEq(mira.balanceOf(bob), INITIAL_MIRA_BALANCE - price);

        // check ask order
        _assertEmptyOrder(nftAddress, tokenId, alice, true);
    }

    function testAcceptAskFail() public {
        uint256 lifetime = 10;
        uint256 price = 100;

        // create ask order
        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), price, block.timestamp + lifetime);
        vm.stopPrank();

        vm.startPrank(bob);
        // AskNotExists
        vm.expectRevert(abi.encodePacked("AskExpiredOrNotExists"));
        market.acceptAsk(address(nft), 2, alice);

        // AskNotExists
        vm.expectRevert(abi.encodePacked("AskExpiredOrNotExists"));
        market.acceptAsk(address(nft1155), 1, alice);

        // NotEnoughCSBFunds
        vm.expectRevert(abi.encodePacked("NotEnoughCSBFunds"));
        market.acceptAsk{value: price - 1}(address(nft), 1, alice);

        // AskExpiredOrNotExists
        skip(lifetime + 1);
        vm.expectRevert(abi.encodePacked("AskExpiredOrNotExists"));
        market.acceptAsk{value: price}(address(nft), 1, alice);
        vm.stopPrank();
    }

    function testAcceptAskFailNotEnoughERC20() public {
        uint256 price = INITIAL_MIRA_BALANCE + 1;

        // create ask order
        vm.prank(alice);
        market.ask(address(nft), 1, address(mira), price, block.timestamp + 10);

        // prepare mira
        vm.startPrank(bob);
        mira.approve(address(market), price);

        vm.expectRevert(abi.encodePacked("ERC777: transfer amount exceeds balance"));
        market.acceptAsk(address(nft), 1, alice);
        vm.stopPrank();
    }

    function testAcceptAskFailNotEnoughERC777() public {
        uint256 price = INITIAL_MIRA_BALANCE + 1;

        // create ask order
        vm.prank(alice);
        market.ask(address(nft), 1, address(mira), price, block.timestamp + 10);

        vm.expectRevert(abi.encodePacked("NotEnougERC777Funds"));
        vm.prank(bob);
        mira.send(address(market), price - 1, abi.encode(address(nft), 1, alice));
    }

    function testAcceptAskFailNotEnoughCSB() public {
        uint256 price = INITIAL_CSB_BALANCE + 1;

        // create ask order
        vm.prank(alice);
        market.ask(address(nft), 1, address(wcsb), price, block.timestamp + 10);

        vm.expectRevert(abi.encodePacked("NotEnoughCSBFunds"));
        vm.prank(bob);
        market.acceptAsk{value: price - 1}(address(nft), 1, alice);
    }

    function testAcceptBidWithRoyalty(uint96 percentage) public {
        vm.assume(percentage <= MAX_ROYALTY);

        uint256 price = 100;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price * percentage) / 10000;

        vm.startPrank(bob);
        // prepare wcsb
        wcsb.deposit{value: 1 ether}();
        wcsb.approve(address(market), 1 ether);
        // bid
        market.bid(address(nft), 1, address(wcsb), price, block.timestamp + 10);
        vm.stopPrank();

        vm.startPrank(alice);
        // set royalty
        nft.setDefaultRoyalty(royaltyReceiver, percentage);
        // approve nft to marketplace
        nft.setApprovalForAll(address(market), true);
        // expect event
        expectEmit(CheckAll);
        emit Events.BidMatched(
            bob,
            address(nft),
            1,
            alice,
            address(wcsb),
            price,
            royaltyReceiver,
            feeAmount
        );
        // accept bid
        market.acceptBid(address(nft), 1, bob);
        vm.stopPrank();

        // check wcsb balance
        assertEq(wcsb.balanceOf(alice), price - feeAmount);
        assertEq(wcsb.balanceOf(royaltyReceiver), feeAmount);
        assertEq(wcsb.balanceOf(bob), 1 ether - price);
    }

    function testAcceptBidWithFuzzingPrice(uint256 price) public {
        vm.assume(price > 100);
        vm.assume(price < 10 ether);

        uint96 percentage = 100;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price * percentage) / 10000;

        vm.startPrank(bob);
        // prepare wcsb
        vm.deal(bob, price);
        wcsb.deposit{value: price}();
        wcsb.approve(address(market), price);
        // bid
        market.bid(address(nft), 1, address(wcsb), price, block.timestamp + 10);
        vm.stopPrank();

        vm.startPrank(alice);
        // set royalty
        nft.setDefaultRoyalty(royaltyReceiver, percentage);
        // approve nft to marketplace
        nft.setApprovalForAll(address(market), true);
        // expect event
        expectEmit(CheckAll);
        emit Events.BidMatched(
            bob,
            address(nft),
            1,
            alice,
            address(wcsb),
            price,
            royaltyReceiver,
            feeAmount
        );
        // accept bid
        market.acceptBid(address(nft), 1, bob);
        vm.stopPrank();

        // check wcsb balance
        assertEq(wcsb.balanceOf(alice), price - feeAmount);
        assertEq(wcsb.balanceOf(royaltyReceiver), feeAmount);
        assertEq(wcsb.balanceOf(bob), 0);
    }

    function testAcceptBid() public {
        uint256 price = 100;

        vm.startPrank(bob);
        // prepare wcsb
        vm.deal(bob, 1 ether);
        wcsb.deposit{value: 1 ether}();
        wcsb.approve(address(market), 1 ether);
        // bid
        market.bid(address(nft), 1, address(wcsb), price, block.timestamp + 10);
        vm.stopPrank();

        vm.startPrank(alice);
        // prepare
        nft.setApprovalForAll(address(market), true);
        // expect event
        expectEmit(CheckAll);
        emit Events.BidMatched(bob, address(nft), 1, alice, address(wcsb), price, address(0x0), 0);
        // accept bid
        market.acceptBid(address(nft), 1, bob);
        vm.stopPrank();

        // check wcsb balance
        assertEq(wcsb.balanceOf(alice), price);
        assertEq(wcsb.balanceOf(bob), 1 ether - price);

        // check bid order
        _assertEmptyOrder(address(nft), 1, bob, false);
    }

    function testAcceptBidFail() public {
        uint256 lifetime = 10;

        // create bid order
        vm.prank(bob);
        market.bid(address(nft), 1, address(wcsb), 100, block.timestamp + lifetime);

        // BidNotExists
        vm.expectRevert(abi.encodePacked("BidNotExists"));
        vm.prank(alice);
        market.acceptBid(address(nft), 2, bob);

        // bidder has insufficient balance
        vm.expectRevert(abi.encodePacked("SafeERC20: low-level call failed"));
        vm.prank(alice);
        market.acceptBid(address(nft), 1, bob);

        vm.deal(bob, 1 ether);
        vm.prank(bob);
        wcsb.deposit{value: 1 ether}();
        // bidder has insufficient allowance
        vm.expectRevert(abi.encodePacked("SafeERC20: low-level call failed"));
        vm.prank(alice);
        market.acceptBid(address(nft), 1, bob);

        vm.prank(bob);
        wcsb.approve(address(market), 1 ether);
        // asker not approved nft to marketplace
        vm.expectRevert(abi.encodePacked("ERC721: caller is not token owner or approved"));
        vm.prank(alice);
        market.acceptBid(address(nft), 1, bob);

        // N seconds later
        skip(lifetime + 1);
        // BidExpired
        vm.expectRevert(abi.encodePacked("BidExpired"));
        vm.prank(alice);
        market.acceptBid(address(nft), 1, bob);
    }

    function _matchOrder(
        DataTypes.Order memory order,
        address owner,
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) internal {
        assertEq(order.owner, owner);
        assertEq(order.nftAddress, nftAddress);
        assertEq(order.tokenId, tokenId);
        assertEq(order.payToken, payToken);
        assertEq(order.price, price);
        assertEq(order.deadline, deadline);
    }

    function _assertEmptyOrder(
        address _nftAddress,
        uint256 _tokenId,
        address _owner,
        bool _isAsk
    ) internal {
        DataTypes.Order memory order = _isAsk
            ? market.getAskOrder(_nftAddress, _tokenId, _owner)
            : market.getBidOrder(_nftAddress, _tokenId, _owner);

        _matchOrder(order, address(0), address(0), 0, address(0), 0, 0);
    }
}
