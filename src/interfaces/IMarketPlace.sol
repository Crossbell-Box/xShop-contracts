// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

interface IMarketPlace {
    function getRoyalty(address token)
        external
        view
        returns (DataTypes.Royalty memory);

    function setRoyalty(
        address token,
        uint256 characterId,
        uint256 noteId,
        address receiver,
        uint8 percentage
    ) external;

    // ask orders
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external;

    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _newPrice,
        uint256 _deadline
    ) external;

    function cancelListing(address _nftAddress, uint256 _tokenId) external;

    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _owner,
        address _payToken
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

    function updateOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    ) external;

    function acceptOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) external;
}
