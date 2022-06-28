// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IMarketPlace.sol";

contract MarketPlace is IMarketPlace {
    uint8 constant SELL = 0;
    uint8 constant OFFER = 1;

    struct Order {
        address owner;
        uint8 orderType;
        address nftAddress;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }

    event ItemListed(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event ItemUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 newPrice
    );

    event ItemCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId
    );

    event OfferCreated(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event OfferCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId
    );

    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price
    );

    // ask orders
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external {}

    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    ) external {}

    function cancelListing(address _nftAddress, uint256 _tokenId) external {}

    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) external {}

    // bid orders
    function createOffer(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external {}

    function cancelOffer(address _nftAddress, uint256 _tokenId) external {}

    function acceptOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) external {}
}
