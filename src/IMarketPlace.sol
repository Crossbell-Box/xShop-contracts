// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMarketPlace {
    // ask orders
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) externa;

    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    ) external;

    function cancelListing(address _nftAddress, uint256 _tokenId) external;

    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) external;

    // bid orders
    function createOffer(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external;

    function cancelOffer(address _nftAddress, uint256 _tokenId) external;

    function acceptOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) external;
}
