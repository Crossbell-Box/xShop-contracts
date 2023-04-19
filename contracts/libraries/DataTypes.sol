// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title DataTypes
 * @notice A standard library of data types.
 */
library DataTypes {
    /**
     * @dev A struct containing the information of an NFT order.
     */
    struct Order {
        address owner;
        address nftAddress;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }
    /**
     * @dev A struct containing the information of a token sell order.
     */
    struct SellOrder {
        address owner;
        uint8 orderType;
        uint256 miraAmount;
        uint256 csbAmount;
    }
}
