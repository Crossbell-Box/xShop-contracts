// SPDX-License-Identifier: MIT
// slither-disable-start naming-convention
pragma solidity 0.8.18;

import {DataTypes} from "../libraries/DataTypes.sol";

contract MarketPlaceStorage {
    address internal _wcsb;
    address internal _mira;

    uint256 internal _askOrderCount;
    //  @notice askOrderId -> Order
    mapping(uint256 askOrderId => DataTypes.Order askOrder) internal _askOrders;
    //  @notice nftAddress -> tokenId -> owner -> askOrderId
    mapping(address nftAddress => mapping(uint256 tokenId => mapping(address owner => uint256 askOrderId)))
        internal _askOrderIds;

    uint256 internal _bidOrderCount;
    //  @notice bidOrderId -> Order
    mapping(uint256 bidOrderId => DataTypes.Order bidOrder) internal _bidOrders;
    //  @notice nftAddress -> tokenId -> owner -> bidOrderId
    mapping(address nftAddress => mapping(uint256 tokenId => mapping(address owner => uint256 bidOrderId)))
        internal _bidOrderIds;
}
// slither-disable-end naming-convention
