// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library DataTypes {
    struct Order {
        address owner;
        address nftAddress;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }
}
