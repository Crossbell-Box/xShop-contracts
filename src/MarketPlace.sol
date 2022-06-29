// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IMarketPlace.sol";
import "./interfaces/IWeb3Entry.sol";
import "./libraries/DataTypes.sol";
import "./libraries/Events.sol";
import "./storage/MarketPlaceStorage.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract MarketPlace is
    IMarketPlace,
    Context,
    Initializable,
    MarketPlaceStorage
{
    uint256 internal constant REVISION = 1;
    bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    modifier expiredOrNotListed(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        DataTypes.Order memory order = listings[_nftAddress][_tokenId][_owner];
        require(order.deadline < _now(), "AlreadyListed");
        _;
    }

    modifier validListing(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        DataTypes.Order memory order = listings[_nftAddress][_tokenId][_owner];
        require(order.deadline >= _now(), "ExpiredOrNotListed");
        _;
    }

    modifier validOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        DataTypes.Order memory order = offers[_nftAddress][_tokenId][_owner];
        require(order.deadline >= _now(), "OfferExpired");
        _;
    }

    modifier offerExpiredOrNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        DataTypes.Order memory order = offers[_nftAddress][_tokenId][_owner];
        require(order.deadline < _now(), "AlreadyOffered");
        _;
    }

    function _validPayToken(address _payToken) internal view {
        require(_payToken == WCSB, "InvalidPayToken");
    }

    function initialize(address _web3Entry, address _wcsb)
        external
        initializer
    {
        web3Entry = _web3Entry;
        WCSB = _wcsb;
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

        emit Events.RoyaltySet(msg.sender, token, receiver, percentage);
    }

    // ask orders
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    ) external expiredOrNotListed(_nftAddress, _tokenId, _msgSender()) {
        _validDeadline(_deadline);
        require(
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721),
            "TokenNotERC721"
        );
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender(),
            "NotERC721TokenOwner"
        );

        _validPayToken(_payToken);

        // save sell order
        listings[_nftAddress][_tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            _nftAddress,
            _tokenId,
            WCSB,
            _price,
            _deadline
        );

        emit Events.ItemListed(
            _msgSender(),
            _nftAddress,
            _tokenId,
            WCSB,
            _price,
            _deadline
        );
    }

    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice,
        uint256 _deadline
    ) external validListing(_nftAddress, _tokenId, _msgSender()) {
        _validDeadline(_deadline);

        DataTypes.Order storage order = listings[_nftAddress][_tokenId][
            _msgSender()
        ];
        // update sell order
        order.price = _newPrice;
        order.deadline = _deadline;

        emit Events.ItemUpdated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            order.payToken,
            _newPrice,
            _deadline
        );
    }

    function cancelListing(address _nftAddress, uint256 _tokenId) external {
        delete listings[_nftAddress][_tokenId][_msgSender()];

        emit Events.ItemCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _owner,
        address _payToken
    ) external validListing(_nftAddress, _tokenId, _owner) {
        DataTypes.Order memory order = listings[_nftAddress][_tokenId][_owner];
        require(order.payToken == _payToken, "InvalidPayToken");

        DataTypes.Royalty memory royalty = royalties[order.nftAddress];
        if (royalty.receiver != address(0)) {
            uint256 feeAmount = (order.price * royalty.percentage) / 100;
            IERC20(order.payToken).transferFrom(
                _msgSender(),
                royalty.receiver,
                feeAmount
            );
            IERC20(order.payToken).transferFrom(
                _msgSender(),
                order.owner,
                order.price - feeAmount
            );
        } else {
            IERC20(order.payToken).transferFrom(
                _msgSender(),
                order.owner,
                order.price
            );
        }

        IERC721(_nftAddress).safeTransferFrom(_owner, _msgSender(), _tokenId);

        emit Events.ItemSold(
            order.owner,
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            order.price
        );

        delete listings[_nftAddress][_tokenId][_owner];
    }

    // bid orders
    function createOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    ) external offerExpiredOrNotExists(_nftAddress, _tokenId, _msgSender()) {
        _validDeadline(_deadline);
        require(
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721),
            "TokenNotERC721"
        );

        _validPayToken(_payToken);

        // save buy order
        offers[_nftAddress][_tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _price,
            _deadline
        );

        emit Events.OfferCreated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _price,
            _deadline
        );
    }

    function cancelOffer(address _nftAddress, uint256 _tokenId) external {
        delete offers[_nftAddress][_tokenId][_msgSender()];

        emit Events.OfferCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    function updateOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _newPrice,
        uint256 _deadline
    ) external validOffer(_nftAddress, _tokenId, _msgSender()) {
        _validDeadline(_deadline);

        _validPayToken(_payToken);

        DataTypes.Order storage order = listings[_nftAddress][_tokenId][
            _msgSender()
        ];
        require(order.deadline >= _now(), "NotListed");
        // update buy order
        order.payToken = _payToken;
        order.price = _newPrice;
        order.deadline = _deadline;

        emit Events.OfferUpdated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _newPrice,
            _deadline
        );
    }

    function acceptOffer(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) external validOffer(_nftAddress, _tokenId, _owner) {
        DataTypes.Order memory order = offers[_nftAddress][_tokenId][_owner];

        DataTypes.Royalty memory royalty = royalties[order.nftAddress];
        if (royalty.receiver != address(0)) {
            uint256 feeAmount = (order.price * royalty.percentage) / 100;
            IERC20(order.payToken).transferFrom(
                order.owner,
                royalty.receiver,
                feeAmount
            );
            IERC20(order.payToken).transferFrom(
                order.owner,
                _msgSender(),
                order.price - feeAmount
            );
        } else {
            IERC20(order.payToken).transferFrom(
                order.owner,
                _msgSender(),
                order.price
            );
        }

        IERC721(_nftAddress).safeTransferFrom(_msgSender(), _owner, _tokenId);

        emit Events.ItemSold(
            _msgSender(),
            order.owner,
            _nftAddress,
            _tokenId,
            order.payToken,
            order.price
        );

        delete offers[_nftAddress][_tokenId][_owner];
    }

    function _now() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _validDeadline(uint256 _deadline) internal view {
        require(_deadline > _now(), "InvalidDeadline");
    }

    function getRevision() external pure returns (uint256) {
        return REVISION;
    }
}
