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

contract MarketPlaceTest is Test {
    MarketPlace market;
    MockWeb3Entry web3Entry;
    WCSB wcsb;
    NFT nft;
    NFT1155 nft1155;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);

    address public dave = address(0x4);
    address public eve = address(0x5);
    address public ferdie = address(0x6);

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

    function testExpectRevertReinitial() public {
        assertEq(market.web3Entry(), address(web3Entry));
        assertEq(market.WCSB(), address(wcsb));

        // reinit
        vm.expectRevert(
            abi.encodePacked("Initializable: contract is already initialized")
        );
        market.initialize(address(0x3), address(0x4));
    }

    function testExpectRevertSetRoyalty() public {
        vm.expectRevert(abi.encodePacked("InvalidPercentage"));
        market.setRoyalty(1, 1, address(0x2), 10001);

        vm.expectRevert(abi.encodePacked("NotCharacterOwner"));
        market.setRoyalty(1, 1, address(0x2), 10000);
    }

    function testExpectRevertSetRoyaltyWithFuzzing(uint256 percentage) public {
        vm.assume(percentage > Constants.MAX_LOYALTY);

        vm.expectRevert(abi.encodePacked("InvalidPercentage"));
        market.setRoyalty(1, 1, address(0x2), percentage);
    }

    function testSetGetRoyaltyWithFuzzing(uint256 percentage) public {
        vm.assume(percentage <= Constants.MAX_LOYALTY);

        // get royalty
        DataTypes.Royalty memory royalty = market.getRoyalty(address(nft));
        assertEq(royalty.receiver, address(0x0));
        assertEq(royalty.percentage, 0);

        // set royalty
        vm.prank(alice);
        market.setRoyalty(1, 1, alice, percentage);

        // get royalty
        royalty = market.getRoyalty(address(nft));
        assertEq(royalty.receiver, alice);
        assertEq(royalty.percentage, percentage);
    }

    function testExpectEmitRoyaltySetWithFuzzing(uint256 percentage) public {
        vm.assume(percentage <= Constants.MAX_LOYALTY);

        vm.expectEmit(true, true, false, true);
        // The event we expect
        emit Events.RoyaltySet(alice, address(nft), alice, percentage);
        // The event we get
        vm.prank(alice);
        market.setRoyalty(1, 1, alice, percentage);
    }

    function testAsk() public {
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

    function testExpectEmitAsk() public {
        vm.expectEmit(true, true, true, true, address(market));
        // The event we expect
        emit Events.AskCreated(alice, address(nft), 1, address(wcsb), 1, 100);
        // The event we get
        vm.prank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 100);
    }

    function testExpectRevertBid() public {
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

    function testExpectEmitBidCreated() public {
        uint256 expiration = block.timestamp + 100;

        vm.expectEmit(true, true, true, true, address(market));
        // The event we expect
        emit Events.BidCreated(
            bob,
            address(nft),
            1,
            address(wcsb),
            1,
            expiration
        );
        // The event we get
        vm.prank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, expiration);
    }

    function testExpectEmitBidCanceled() public {
        uint256 expiration = block.timestamp + 100;

        vm.startPrank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, expiration);

        vm.expectEmit(true, true, true, false, address(market));
        // The event we expect
        emit Events.BidCanceled(bob, address(nft), 1);
        // The event we get
        market.cancelBid(address(nft), 1);
        vm.stopPrank();
    }

    function testExpectEmitBidUpdated() public {
        uint256 expiration = block.timestamp + 100;

        vm.startPrank(bob);
        market.bid(address(nft), 1, address(wcsb), 1, expiration);

        vm.expectEmit(true, true, true, false, address(market));
        // The event we expect
        emit Events.BidUpdated(
            bob,
            address(nft),
            1,
            address(wcsb),
            2,
            expiration + 1
        );
        // The event we get
        market.updateBid(address(nft), 1, address(wcsb), 2, expiration + 1);
        vm.stopPrank();
    }

    function testUpdateAsk() public {
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

        vm.expectRevert(abi.encodePacked("InvalidPrice"));
        market.updateAsk(address(nft), 1, address(wcsb), 0, 100);
        vm.stopPrank();
    }

    function testExpectEmitUpdateAsk() public {
        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 100);
        vm.expectEmit(true, true, true, true, address(market));
        // The event we expect
        emit Events.AskUpdated(alice, address(nft), 1, address(wcsb), 1, 101);
        // The event we get
        market.updateAsk(address(nft), 1, address(wcsb), 1, 101);
        vm.stopPrank();
    }

    function cancelAsk() public {
        // AskNotExists
        vm.expectRevert(abi.encodePacked("AskNotExists"));
        vm.prank(alice);
        market.cancelAsk(address(nft), 1);
    }

    function testExpectEmitCancelAsk() public {
        vm.startPrank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 100);
        vm.expectEmit(true, true, true, false, address(market));
        emit Events.AskCanceled(alice, address(nft), 1);
        market.cancelAsk(address(nft), 1);
        vm.stopPrank();
    }

    function testAcceptAsk() public {
        // AskExpired
        vm.prank(alice);
        market.ask(address(nft), 1, address(wcsb), 1, 100);
        vm.prank(address(0x555));
        skip(200); // blocktimestamp +200
        vm.expectRevert(abi.encodePacked("AskExpiredOrNotExists"));
        market.acceptAsk(address(nft), 1, alice);

        // AskNotExists
        vm.expectRevert(abi.encodePacked("AskExpiredOrNotExists"));
        market.acceptAsk(address(nft), 2, alice);
    }

    function testExpectEmitAcceptAsk() public {
        // vm.prank(alice);
        // market.ask(address(nft), 1, address(wcsb), 1, 100);
        // vm.prank(address(0x555));
        // vm.deal(address(0x555), 10000 ether);
        // console.log(address(0x555).balance);
        // market.acceptAsk(address(nft),1, alice);
        // console.log(address(0x555).balance);
    }
}
