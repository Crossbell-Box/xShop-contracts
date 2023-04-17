// SPDX-License-Identifier: MIT
// slither-disable-start naming-convention
pragma solidity 0.8.16;

import {DataTypes} from "../libraries/DataTypes.sol";

contract MarketPlaceStorage {
    // solhint-disable-next-line var-name-mixedcase
    address public WCSB;

    //  @notice nftAddress -> tokenId -> owner -> Order
    mapping(address => mapping(uint256 => mapping(address => DataTypes.Order))) internal _askOrders;

    //  @notice nftAddress -> tokenId -> owner -> Order
    mapping(address => mapping(uint256 => mapping(address => DataTypes.Order))) internal _bidOrders;
}
// slither-disable-end naming-convention
