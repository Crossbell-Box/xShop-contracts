// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.16;

import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "../contracts/MarketPlace.sol";
import {DataTypes} from "../contracts/libraries/DataTypes.sol";
import {Constants} from "../contracts/libraries/Constants.sol";
import {Events} from "../contracts/libraries/Events.sol";
import {MockWeb3Entry} from "./mocks/MockWeb3Entry.sol";
import {WCSB} from "./mocks/WCSB.sol";
import {NFT, NFT1155} from "./mocks/NFT.sol";
import {EmitExpecter} from "./EmitExpecter.sol";

contract MarketPlaceTest is Test, EmitExpecter {
    MarketPlace market;
    MockWeb3Entry web3Entry;
    WCSB wcsb;
    NFT nft;
    NFT1155 nft1155;

    // ask accounts
    address public alice = address(0x1111);

    // bid accounts
    address public bob = address(0x2222);

    function setUp() public {
        market = new MarketPlace();
        wcsb = new WCSB();
        nft = new NFT();
        nft1155 = new NFT1155();
        web3Entry = new MockWeb3Entry(address(nft)); //address(nft) is mintNoteNFT address
        market.initialize(address(web3Entry), address(wcsb));

        nft.mint(alice);
        nft1155.mint(alice);
        web3Entry.mintCharacter(alice);
    }

    function testWeb3Entry() public {
        assertEq(market.web3Entry(), address(web3Entry));
    }

    function testWCSB() public {
        assertEq(market.WCSB(), address(wcsb));
    }

    function testInitFail() public {
        // reinit
        vm.expectRevert(abi.encodePacked("Initializable: contract is already initialized"));
        market.initialize(address(0x3), address(0x4));
    }

    function testSetRoyaltyFail(uint256 percentage) public {
        vm.assume(percentage > Constants.MAX_ROYALTY);

        address receiver = address(0x1234);

        vm.expectRevert(abi.encodePacked("InvalidPercentage"));
        market.setRoyalty(1, 1, receiver, percentage);

        vm.expectRevert(abi.encodePacked("NotCharacterOwner"));
        vm.prank(bob); // bob is not character owner
        market.setRoyalty(1, 1, receiver, 10000);

        vm.expectRevert(abi.encodePacked("NoMintNFT"));
        vm.prank(alice); // alice is character owner
        market.setRoyalty(1, 2, receiver, 10000);
    }

    function testSetRoyalty(uint256 percentage) public {
        vm.assume(percentage <= Constants.MAX_ROYALTY);

        address feeReceiver = address(0x1234);

        // get royalty
        DataTypes.Royalty memory royalty = market.getRoyalty(address(nft));
        assertEq(royalty.receiver, address(0x0));
        assertEq(royalty.percentage, 0);

        expectEmit(CheckTopic1 | CheckTopic2 | CheckData);
        // The event we expect
        emit Events.RoyaltySet(alice, address(nft), feeReceiver, percentage);
        // The event we get
        vm.prank(alice);
        market.setRoyalty(1, 1, feeReceiver, percentage);

        // get royalty
        royalty = market.getRoyalty(address(nft));
        assertEq(royalty.receiver, feeReceiver);
        assertEq(royalty.percentage, percentage);
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

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        // The event we expect
        emit Events.AskCreated(alice, address(nft), 1, address(wcsb), 1, expiration);
        // The event we get
        vm.prank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, expiration);

        DataTypes.Order memory order = market.getAskOrder(address(nft), 1, alice);
        // check ask order
        assertEq(order.owner, alice);
        assertEq(order.nftAddress, address(nft));
        assertEq(order.tokenId, 1);
        assertEq(order.payToken, address(wcsb));
        assertEq(order.price, 1);
        assertEq(order.deadline, expiration);
    }

    function testBidFail() public {
        uint256 expiration = block.timestamp + 10;

        vm.expectRevert(abi.encodePacked("InvalidPayToken"));
        market.bid(address(nft), 1, address(0x567), 1, expiration);

        vm.expectRevert(abi.encodePacked("NativeCSBNotAllowed"));
        market.bid(address(nft), 1, Constants.NATIVE_CSB, 100, expiration);

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

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        // The event we expect
        emit Events.BidCreated(bob, address(nft), 1, address(wcsb), 1, expiration);
        // The event we get
        vm.prank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, expiration);

        // check bid order
        DataTypes.Order memory order = market.getBidOrder(address(nft), 1, bob);
        // check ask order
        assertEq(order.owner, bob);
        assertEq(order.nftAddress, address(nft));
        assertEq(order.tokenId, 1);
        assertEq(order.payToken, address(wcsb));
        assertEq(order.price, 1);
        assertEq(order.deadline, expiration);
    }

    function testCancelBid() public {
        uint256 expiration = block.timestamp + 100;

        vm.startPrank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, expiration);

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3);
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

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        // The event we expect
        emit Events.BidUpdated(bob, address(nft), 1, Constants.NATIVE_CSB, 100, expiration);
        // The event we get
        market.updateBid(address(nft), 1, Constants.NATIVE_CSB, 100, expiration);

        DataTypes.Order memory order = market.getBidOrder(address(nft), 1, bob);
        // check bid order
        assertEq(order.owner, bob);
        assertEq(order.nftAddress, address(nft));
        assertEq(order.tokenId, 1);
        assertEq(order.payToken, Constants.NATIVE_CSB);
        assertEq(order.price, 100);
        assertEq(order.deadline, expiration);
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

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        // The event we expect
        emit Events.AskUpdated(alice, address(nft), 1, Constants.NATIVE_CSB, 100, expiration);
        // The event we get
        market.updateAsk(address(nft), 1, Constants.NATIVE_CSB, 100, expiration);

        DataTypes.Order memory order = market.getAskOrder(address(nft), 1, alice);
        // check ask order
        assertEq(order.owner, alice);
        assertEq(order.nftAddress, address(nft));
        assertEq(order.tokenId, 1);
        assertEq(order.payToken, Constants.NATIVE_CSB);
        assertEq(order.price, 100);
        assertEq(order.deadline, expiration);
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

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3);
        emit Events.AskCanceled(alice, address(nft), 1);
        market.cancelAsk(address(nft), 1);
        vm.stopPrank();

        // check ask order
        _assertEmptyOrder(address(nft), 1, alice, true);
    }

    function testAcceptAsk() public {
        uint256 price = 100;

        // ask
        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), price, block.timestamp + 10);
        vm.stopPrank();

        // prepare wcsb
        vm.startPrank(bob);
        vm.deal(bob, 1 ether);
        wcsb.deposit{value: 1 ether}();
        wcsb.approve(address(market), 1 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        // prepare
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();
        // expect event
        vm.startPrank(bob);
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.OrdersMatched(
            alice,
            bob,
            address(nft),
            1,
            address(wcsb),
            price,
            address(0x0),
            0
        );
        // accept ask
        market.acceptAsk(address(nft), 1, alice);
        vm.stopPrank();

        // check wcsb balance
        assertEq(wcsb.balanceOf(alice), price);
        assertEq(wcsb.balanceOf(bob), 1 ether - price);

        // check ask order
        _assertEmptyOrder(address(nft), 1, alice, true);
    }

    function testAcceptAskWithCSB() public {
        uint256 price = 100;

        //  create ask order
        vm.startPrank(alice);
        market.ask(address(nft), 1, Constants.NATIVE_CSB, price, block.timestamp + 10);
        // prepare
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // expect event
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.OrdersMatched(
            alice,
            bob,
            address(nft),
            1,
            Constants.NATIVE_CSB,
            price,
            address(0x0),
            0
        );
        // accept ask
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        market.acceptAsk{value: price}(address(nft), 1, alice);

        // check csb balance
        assertEq(alice.balance, price);
        assertEq(bob.balance, 1 ether - price);

        // check ask order
        _assertEmptyOrder(address(nft), 1, alice, true);
    }

    function testAcceptAskWithCSBWithRoyalty(uint256 percentage) public {
        vm.assume(percentage <= Constants.MAX_ROYALTY);

        uint256 price = 100;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price / 10000) * percentage;

        //  create ask order
        vm.startPrank(alice);
        market.setRoyalty(1, 1, royaltyReceiver, percentage);
        market.ask(address(nft), 1, Constants.NATIVE_CSB, price, block.timestamp + 10);
        // prepare
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // expect event
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.OrdersMatched(
            alice,
            bob,
            address(nft),
            1,
            Constants.NATIVE_CSB,
            price,
            royaltyReceiver,
            feeAmount
        );
        // accept ask
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        market.acceptAsk{value: price}(address(nft), 1, alice);

        // check csb balance
        assertEq(alice.balance, price - feeAmount);
        assertEq(royaltyReceiver.balance, feeAmount);
        assertEq(bob.balance, 1 ether - price);

        // check ask order
        _assertEmptyOrder(address(nft), 1, alice, true);
    }

    function testAcceptAskWithWCSBWithRoyalty(uint256 percentage) public {
        vm.assume(percentage <= Constants.MAX_ROYALTY);

        uint256 price = 1000;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price / 10000) * percentage;

        //  create ask order
        vm.startPrank(alice);
        market.setRoyalty(1, 1, royaltyReceiver, percentage);
        market.ask(address(nft), 1, address(wcsb), price, block.timestamp + 10);
        // prepare
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // expect event
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.OrdersMatched(
            alice,
            bob,
            address(nft),
            1,
            address(wcsb),
            price,
            royaltyReceiver,
            feeAmount
        );
        // accept ask
        vm.deal(bob, 2 ether);
        vm.startPrank(bob);
        wcsb.deposit{value: 1 ether}();
        wcsb.approve(address(market), price);
        market.acceptAsk(address(nft), 1, alice);
        vm.stopPrank();

        // check wcsb balance
        assertEq(wcsb.balanceOf(alice), price - feeAmount);
        assertEq(wcsb.balanceOf(royaltyReceiver), feeAmount);
        assertEq(wcsb.balanceOf(bob), 1 ether - price);

        // check ask order
        _assertEmptyOrder(address(nft), 1, alice, true);
    }

    function testAcceptAskWithFuzzingPrice(uint256 price) public {
        vm.assume(price > 1);

        uint256 percentage = 100;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price / 10000) * percentage;

        //  create ask order
        vm.startPrank(alice);
        market.setRoyalty(1, 1, royaltyReceiver, percentage);
        market.ask(address(nft), 1, address(wcsb), price, block.timestamp + 10);
        // prepare
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // expect event
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.OrdersMatched(
            alice,
            bob,
            address(nft),
            1,
            address(wcsb),
            price,
            royaltyReceiver,
            feeAmount
        );
        // accept ask
        vm.deal(bob, price);
        vm.startPrank(bob);
        wcsb.deposit{value: price}();
        wcsb.approve(address(market), price);
        market.acceptAsk(address(nft), 1, alice);
        vm.stopPrank();

        // check wcsb balance
        assertEq(wcsb.balanceOf(alice), price - feeAmount);
        assertEq(wcsb.balanceOf(royaltyReceiver), feeAmount);
        assertEq(wcsb.balanceOf(bob), 0);

        // check ask order
        _assertEmptyOrder(address(nft), 1, alice, true);
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

        // bidder has insufficient balance
        vm.expectRevert(abi.encodePacked("SafeERC20: low-level call failed"));
        market.acceptAsk(address(nft), 1, alice);

        // bidder has insufficient balance
        vm.deal(bob, 1 ether);
        wcsb.deposit{value: price - 1}();
        wcsb.approve(address(market), 1 ether);
        vm.expectRevert(abi.encodePacked("SafeERC20: low-level call failed"));
        market.acceptAsk(address(nft), 1, alice);

        // bidder has insufficient allowance
        wcsb.deposit{value: 1}();
        wcsb.approve(address(market), price - 1);
        vm.expectRevert(abi.encodePacked("SafeERC20: low-level call failed"));
        market.acceptAsk(address(nft), 1, alice);

        // AskExpiredOrNotExists
        skip(lifetime + 1);
        vm.expectRevert(abi.encodePacked("AskExpiredOrNotExists"));
        market.acceptAsk(address(nft), 1, alice);
        vm.stopPrank();
    }

    function testAcceptBidWithRoyalty(uint256 percentage) public {
        vm.assume(percentage <= Constants.MAX_ROYALTY);

        uint256 price = 100;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price / 10000) * percentage;

        vm.startPrank(bob);
        // prepare wcsb
        vm.deal(bob, 1 ether);
        wcsb.deposit{value: 1 ether}();
        wcsb.approve(address(market), 1 ether);
        // bid
        market.bid(address(nft), 1, address(wcsb), price, block.timestamp + 10);
        vm.stopPrank();

        vm.startPrank(alice);
        // set royalty
        market.setRoyalty(1, 1, royaltyReceiver, percentage);
        // approve nft to marketplace
        nft.setApprovalForAll(address(market), true);
        // expect event
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.OrdersMatched(
            alice,
            bob,
            address(nft),
            1,
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

        uint256 percentage = 100;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price / 10000) * percentage;

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
        market.setRoyalty(1, 1, royaltyReceiver, percentage);
        // approve nft to marketplace
        nft.setApprovalForAll(address(market), true);
        // expect event
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.OrdersMatched(
            alice,
            bob,
            address(nft),
            1,
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
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        emit Events.OrdersMatched(
            alice,
            bob,
            address(nft),
            1,
            address(wcsb),
            price,
            address(0x0),
            0
        );
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

    function _assertEmptyOrder(
        address _nftAddress,
        uint256 _tokenId,
        address _owner,
        bool _isAsk
    ) internal {
        DataTypes.Order memory order = _isAsk
            ? market.getAskOrder(_nftAddress, _tokenId, _owner)
            : market.getBidOrder(_nftAddress, _tokenId, _owner);

        assertEq(order.owner, address(0));
        assertEq(order.nftAddress, address(0));
        assertEq(order.tokenId, 0);
        assertEq(order.payToken, address(0));
        assertEq(order.price, 0);
        assertEq(order.deadline, 0);
    }
}
