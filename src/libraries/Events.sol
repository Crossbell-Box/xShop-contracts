// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Events {
    event RoyaltySet(
        address indexed owner,
        address indexed nftAddress,
        address receiver,
        uint256 percentage
    );

    event ItemListed(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event ItemUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 newPrice,
        uint256 deadline
    );

    event ItemCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event OfferCreated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event OfferCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event OfferUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 newPrice,
        uint256 deadline
    );

    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price
    );
}