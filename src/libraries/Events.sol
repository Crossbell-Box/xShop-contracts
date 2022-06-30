// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Events {
    event RoyaltySet(
        address indexed owner,
        address indexed nftAddress,
        address receiver,
        uint256 percentage
    );

    event AskCreated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event AskUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 newPrice,
        uint256 deadline
    );

    event AskCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event BidCreated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event BidCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event BidUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 newPrice,
        uint256 deadline
    );

    event OrdersMatched(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price
    );
}
