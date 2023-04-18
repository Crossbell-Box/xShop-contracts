// SPDX-License-Identifier: MIT
// slither-disable-start naming-convention
pragma solidity 0.8.16;

import {DataTypes} from "../libraries/DataTypes.sol";

contract MarketPlaceStorage {
    address internal _wcsb;
    address internal _mira;

    //  @notice nftAddress -> tokenId -> owner -> Order
    mapping(address => mapping(uint256 => mapping(address => DataTypes.Order))) internal _askOrders;

    //  @notice nftAddress -> tokenId -> owner -> Order
    mapping(address => mapping(uint256 => mapping(address => DataTypes.Order))) internal _bidOrders;
}
// slither-disable-end naming-convention
