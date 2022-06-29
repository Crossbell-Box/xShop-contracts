// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IMarketPlace.sol";
import "./interfaces/IWeb3Entry.sol";
import "./libraries/DataTypes.sol";
import "./libraries/Events.sol";
import "./storage/MarketPlaceStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract MarketPlace is IMarketPlace, Initializable, MarketPlaceStorage {
    uint256 internal constant REVISION = 1;

    function initialize(address _web3Entry) external initializer {
        web3Entry = _web3Entry;
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
        // check character owner
        require(
            msg.sender == IERC721(web3Entry).ownerOf(characterId),
            "NotCharacterOwner"
        );
        // check token address and owner
        DataTypes.Note memory note = IWeb3Entry(web3Entry).getNote(
            characterId,
            noteId
        );
        require(note.mintNFT == token, "InvalidToken");

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

    function getRevision() external pure returns (uint256) {
        return REVISION;
    }
}
