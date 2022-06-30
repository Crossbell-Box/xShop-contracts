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

    modifier expiredOrNotAsked(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][
            _owner
        ];
        require(askOrder.deadline < _now(), "AlreadyAsked");
        _;
    }

    modifier validAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][
            _owner
        ];
        require(askOrder.deadline >= _now(), "ExpiredOrNotAsked");
        _;
    }

    modifier validBid(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][
            _owner
        ];
        require(bidOrder.deadline >= _now(), "BidExpired");
        _;
    }

    modifier bidExpiredOrNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][
            _owner
        ];
        require(bidOrder.deadline < _now(), "AlreadyBid");
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

        royalties[note.mintNFT].receiver = receiver;
        royalties[note.mintNFT].percentage = percentage;

        emit Events.RoyaltySet(msg.sender, note.mintNFT, receiver, percentage);
    }

    // ask orders
    function ask(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    ) external expiredOrNotAsked(_nftAddress, _tokenId, _msgSender()) {
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
        askOrders[_nftAddress][_tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            _nftAddress,
            _tokenId,
            WCSB,
            _price,
            _deadline
        );

        emit Events.AskCreated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            WCSB,
            _price,
            _deadline
        );
    }

    function updateAsk(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice,
        uint256 _deadline
    ) external validAsk(_nftAddress, _tokenId, _msgSender()) {
        _validDeadline(_deadline);

        DataTypes.Order storage askOrder = askOrders[_nftAddress][_tokenId][
            _msgSender()
        ];
        // update sell order
        askOrder.price = _newPrice;
        askOrder.deadline = _deadline;

        emit Events.AskUpdated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            askOrder.payToken,
            _newPrice,
            _deadline
        );
    }

    function cancelAsk(address _nftAddress, uint256 _tokenId) external {
        delete askOrders[_nftAddress][_tokenId][_msgSender()];

        emit Events.AskCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    function acceptAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _owner,
        address _payToken
    ) external validAsk(_nftAddress, _tokenId, _owner) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][
            _owner
        ];
        require(askOrder.payToken == _payToken, "InvalidPayToken");

        DataTypes.Royalty memory royalty = royalties[askOrder.nftAddress];
        if (royalty.receiver != address(0)) {
            uint256 feeAmount = (askOrder.price * royalty.percentage) / 100;
            IERC20(askOrder.payToken).transferFrom(
                _msgSender(),
                royalty.receiver,
                feeAmount
            );
            IERC20(askOrder.payToken).transferFrom(
                _msgSender(),
                askOrder.owner,
                askOrder.price - feeAmount
            );
        } else {
            IERC20(askOrder.payToken).transferFrom(
                _msgSender(),
                askOrder.owner,
                askOrder.price
            );
        }

        IERC721(_nftAddress).safeTransferFrom(_owner, _msgSender(), _tokenId);

        emit Events.OrdersMatched(
            askOrder.owner,
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            askOrder.price
        );

        delete askOrders[_nftAddress][_tokenId][_owner];
    }

    // bid orders
    function bid(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    ) external bidExpiredOrNotExists(_nftAddress, _tokenId, _msgSender()) {
        _validDeadline(_deadline);
        require(
            IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721),
            "TokenNotERC721"
        );

        _validPayToken(_payToken);

        // save buy order
        bidOrders[_nftAddress][_tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _price,
            _deadline
        );

        emit Events.BidCreated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _price,
            _deadline
        );
    }

    function cancelBid(address _nftAddress, uint256 _tokenId) external {
        delete bidOrders[_nftAddress][_tokenId][_msgSender()];

        emit Events.BidCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    function updateBid(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _newPrice,
        uint256 _deadline
    ) external validBid(_nftAddress, _tokenId, _msgSender()) {
        _validDeadline(_deadline);

        _validPayToken(_payToken);

        DataTypes.Order storage bidOrder = askOrders[_nftAddress][_tokenId][
            _msgSender()
        ];
        require(bidOrder.deadline >= _now(), "NotListed");
        // update buy order
        bidOrder.payToken = _payToken;
        bidOrder.price = _newPrice;
        bidOrder.deadline = _deadline;

        emit Events.BidUpdated(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _newPrice,
            _deadline
        );
    }

    function acceptBid(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) external validBid(_nftAddress, _tokenId, _owner) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][
            _owner
        ];

        DataTypes.Royalty memory royalty = royalties[bidOrder.nftAddress];
        if (royalty.receiver != address(0)) {
            uint256 feeAmount = (bidOrder.price * royalty.percentage) / 100;
            IERC20(bidOrder.payToken).transferFrom(
                bidOrder.owner,
                royalty.receiver,
                feeAmount
            );
            IERC20(bidOrder.payToken).transferFrom(
                bidOrder.owner,
                _msgSender(),
                bidOrder.price - feeAmount
            );
        } else {
            IERC20(bidOrder.payToken).transferFrom(
                bidOrder.owner,
                _msgSender(),
                bidOrder.price
            );
        }

        IERC721(_nftAddress).safeTransferFrom(_msgSender(), _owner, _tokenId);

        emit Events.OrdersMatched(
            _msgSender(),
            bidOrder.owner,
            _nftAddress,
            _tokenId,
            bidOrder.payToken,
            bidOrder.price
        );

        delete bidOrders[_nftAddress][_tokenId][_owner];
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
