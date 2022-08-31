// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

contract MarketPlaceStorage {
    address public web3Entry; // slot 10
    address public WCSB;

    //  @notice nftAddress -> tokenId -> owner -> Order
    mapping(address => mapping(uint256 => mapping(address => DataTypes.Order))) internal askOrders;

    //  @notice nftAddress -> tokenId -> owner -> Order
    mapping(address => mapping(uint256 => mapping(address => DataTypes.Order))) internal bidOrders;

    // @notice nftAddress -> Royalty
    mapping(address => DataTypes.Royalty) internal royalties;
}
