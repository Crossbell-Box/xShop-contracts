// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library DataTypes {
    struct Order {
        address owner;
        address nftAddress;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }

    struct SellOrder {
        address owner;
        uint8 orderType;
        uint256 miraAmount;
        uint256 csbAmount;
    }
}
