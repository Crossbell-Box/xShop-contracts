// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@std/Test.sol";
import "@std/console2.sol";
import "../MarketPlace.sol";
import "../libraries/DataTypes.sol";
import "../libraries/Constants.sol";
import "../libraries/Events.sol";
import "../mocks/MockWeb3Entry.sol";
import "../mocks/WCSB.sol";
import "../mocks/NFT.sol";
import "./EmitExpecter.sol";

contract MarketPlaceTest is Test, EmitExpecter {
    MarketPlace market;
    MockWeb3Entry web3Entry;
    WCSB wcsb;
    NFT nft;
    NFT1155 nft1155;

    // ask accounts
    address public alice = address(0x1);
    address public charlie = address(0x3);

    // bid accounts
    address public bob = address(0x2);
    address public dave = address(0x4);

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

    function testInitFail() public {
        assertEq(market.web3Entry(), address(web3Entry));
        assertEq(market.WCSB(), address(wcsb));

        // reinit
        vm.expectRevert(abi.encodePacked("Initializable: contract is already initialized"));
        market.initialize(address(0x3), address(0x4));
    }

    function testSetRoyaltyFail(uint256 percentage) public {
        vm.assume(percentage > Constants.MAX_ROYALTY);

        vm.expectRevert(abi.encodePacked("InvalidPercentage"));
        market.setRoyalty(1, 1, address(0x2), percentage);

        vm.expectRevert(abi.encodePacked("NotCharacterOwner"));
        market.setRoyalty(1, 1, address(0x2), 10000);
    }

    function testSetGetRoyalty(uint256 percentage) public {
        vm.assume(percentage <= Constants.MAX_ROYALTY);

        // get royalty
        DataTypes.Royalty memory royalty = market.getRoyalty(address(nft));
        assertEq(royalty.receiver, address(0x0));
        assertEq(royalty.percentage, 0);

        expectEmit(CheckTopic1 | CheckTopic2 | CheckData);
        // The event we expect
        emit Events.RoyaltySet(alice, address(nft), alice, percentage);
        // The event we get
        vm.prank(alice);
        market.setRoyalty(1, 1, alice, percentage);

        // get royalty
        royalty = market.getRoyalty(address(nft));
        assertEq(royalty.receiver, alice);
        assertEq(royalty.percentage, percentage);
    }

    function testAskFail() public {
        vm.expectRevert(abi.encodePacked("InvalidDeadline"));
        market.ask(address(nft), 1, address(wcsb), 1, block.timestamp);

        vm.expectRevert(abi.encodePacked("TokenNotERC721"));
        market.ask(address(nft1155), 1, address(wcsb), 1, 100);

        vm.prank(address(0x1000));
        vm.expectRevert(abi.encodePacked("NotERC721TokenOwner"));
        market.ask(address(nft), 1, address(wcsb), 1, 100);

        vm.startPrank(alice);
        vm.expectRevert(abi.encodePacked("InvalidPayToken"));
        market.ask(address(nft), 1, address(0x567), 1, 100);

        vm.expectRevert(abi.encodePacked("InvalidPrice"));
        market.ask(address(nft), 1, address(wcsb), 0, 100);
        vm.stopPrank();
    }

    function testAsk() public {
        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        // The event we expect
        emit Events.AskCreated(alice, address(nft), 1, address(wcsb), 1, 100);
        // The event we get
        vm.prank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 100);
    }

    function testBidFail() public {
        vm.expectRevert(abi.encodePacked("InvalidDeadline"));
        market.bid(address(nft), 1, address(wcsb), 1, block.timestamp);

        vm.expectRevert(abi.encodePacked("InvalidPayToken"));
        market.bid(address(nft), 1, address(0x567), 1, 100);

        vm.expectRevert(abi.encodePacked("TokenNotERC721"));
        market.bid(address(nft1155), 1, address(wcsb), 1, 100);

        market.bid(address(nft), 1, address(wcsb), 1, block.timestamp + 10);
        vm.expectRevert(abi.encodePacked("BidExists"));
        market.bid(address(nft), 1, address(wcsb), 1, block.timestamp + 100);
    }

    function testBid() public {
        uint256 expiration = block.timestamp + 100;

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        // The event we expect
        emit Events.BidCreated(bob, address(nft), 1, address(wcsb), 1, expiration);
        // The event we get
        vm.prank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, expiration);
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
        market.bid(address(nft), 1, address(wcsb), 1, expiration);

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        // The event we expect
        emit Events.BidUpdated(bob, address(nft), 1, address(wcsb), 2, expiration + 1);
        // The event we get
        market.updateBid(address(nft), 1, address(wcsb), 2, expiration + 1);
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
        // not existed
        vm.expectRevert(abi.encodePacked("AskNotExists"));
        market.updateAsk(address(0x678), 1, address(wcsb), 1, 3);
        // not owner(actually the same as notExisted)
        vm.prank(address(0x6789));
        vm.expectRevert(abi.encodePacked("AskNotExists"));
        market.updateAsk(address(nft), 1, address(wcsb), 1, 3);

        // invalid deadline
        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 100);

        vm.expectRevert(abi.encodePacked("InvalidDeadline"));
        market.updateAsk(address(nft), 1, address(wcsb), 1, block.timestamp);

        // invalid pay token
        vm.expectRevert(abi.encodePacked("InvalidPayToken"));
        market.updateAsk(address(nft), 1, address(0x567), 1, 100);

        // invalid price
        vm.expectRevert(abi.encodePacked("InvalidPrice"));
        market.updateAsk(address(nft), 1, address(wcsb), 0, 100);
        vm.stopPrank();
    }

    function testUpdateAsk() public {
        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 100);

        expectEmit(CheckTopic1 | CheckTopic2 | CheckTopic3 | CheckData);
        // The event we expect
        emit Events.AskUpdated(alice, address(nft), 1, address(wcsb), 1, 101);
        // The event we get
        market.updateAsk(address(nft), 1, address(wcsb), 1, 101);
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
    }

    function testAcceptAskFail() public {
        // AskExpired
        vm.prank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 100);
        vm.prank(address(0x555));
        skip(200); // blocktimestamp + 200
        vm.expectRevert(abi.encodePacked("AskExpiredOrNotExists"));
        market.acceptAsk(address(nft), 1, alice);

        // AskNotExists
        vm.expectRevert(abi.encodePacked("AskExpiredOrNotExists"));
        market.acceptAsk(address(nft), 2, alice);
    }

    function testAcceptBidWithRoyalty(uint256 percentage) public {
        vm.assume(percentage <= Constants.MAX_ROYALTY);

        uint256 price = 100;
        address royaltyReceiver = address(0x5555);
        uint256 feeAmount = (price * percentage) / 10000;

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
    }

    function testAcceptBidFail() public {
        uint256 lifetime = 10;

        // create bid
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
        vm.expectRevert(abi.encodePacked("ERC721: caller is not token owner nor approved"));
        vm.prank(alice);
        market.acceptBid(address(nft), 1, bob);

        // N seconds later
        skip(lifetime + 1);
        // BidExpired
        vm.expectRevert(abi.encodePacked("BidExpired"));
        vm.prank(alice);
        market.acceptBid(address(nft), 1, bob);
    }
}
