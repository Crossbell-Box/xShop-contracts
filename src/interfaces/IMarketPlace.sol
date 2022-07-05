// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

interface IMarketPlace {
    function getRoyalty(address token)
        external
        view
        returns (DataTypes.Royalty memory);

    function setRoyalty(
        uint256 characterId,
        uint256 noteId,
        address receiver,
        uint256 percentage
    ) external;

    function ask(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external;

    function updateAsk(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice,
        uint256 _deadline
    ) external;

    function cancelAsk(address _nftAddress, uint256 _tokenId) external;

    function acceptAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) external;

    function bid(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external;

    function cancelBid(address _nftAddress, uint256 _tokenId) external;

    function updateBid(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    ) external;

    function acceptBid(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) external;
}
