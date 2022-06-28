// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IMarketPlace.sol";
import "./libraries/DataTypes.sol";
import "./MarketPlaceStorage.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract MarketPlace is IMarketPlace, Initializable, MarketPlaceStorage {
    event ItemListed(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event ItemUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 newPrice
    );

    event ItemCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId
    );

    event OfferCreated(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event OfferCanceled(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId
    );

    event ItemSold(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price
    );

    function initialize(address _web3Entry) external initializer {
        Web3Entry = _web3Entry;
    }

    function getRoyalty(address token)
        external
        view
        returns (DataTypes.Royalty memory)
    {
        return royalties[token];
    }

    function setRoyalty(
        address token,
        uint256 characterId,
        uint256 noteId,
        address receiver,
        uint8 percentage
    ) external {
        require(percentage <= 100, "InvalidPercentage");

        // TODO: check token address and owner

        royalties[token].receiver = receiver;
        royalties[token].percentage = percentage;
    }

    // ask orders
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external {}

    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    ) external {}

    function cancelListing(address _nftAddress, uint256 _tokenId) external {}

    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) external {}

    // bid orders
    function createOffer(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external {}

    function cancelOffer(address _nftAddress, uint256 _tokenId) external {}

    function acceptOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) external {}
}
