// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IMarketPlace} from "./interfaces/IMarketPlace.sol";
import {IWCSB} from "./interfaces/IWCSB.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Events} from "./libraries/Events.sol";
import {MarketPlaceStorage} from "./storage/MarketPlaceStorage.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketPlace is IMarketPlace, Context, ReentrancyGuard, Initializable, MarketPlaceStorage {
    using SafeERC20 for IERC20;

    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    modifier askNotExists(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory askOrder = _askOrders[nftAddress][tokenId][user];
        require(askOrder.deadline == 0, "AskExists");
        _;
    }

    modifier askExists(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory askOrder = _askOrders[nftAddress][tokenId][user];
        require(askOrder.deadline > 0, "AskNotExists");
        _;
    }

    modifier validAsk(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory askOrder = _askOrders[nftAddress][tokenId][user];
        require(askOrder.deadline >= _now(), "AskExpiredOrNotExists");
        _;
    }

    modifier bidNotExists(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory bidOrder = _bidOrders[nftAddress][tokenId][user];
        require(bidOrder.deadline == 0, "BidExists");
        _;
    }

    modifier bidExists(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory bidOrder = _bidOrders[nftAddress][tokenId][user];
        require(bidOrder.deadline > 0, "BidNotExists");
        _;
    }

    modifier validBid(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory bidOrder = _bidOrders[nftAddress][tokenId][user];
        require(bidOrder.deadline != 0, "BidNotExists");
        require(bidOrder.deadline >= _now(), "BidExpired");
        _;
    }

    modifier validPayToken(address payToken) {
        require(payToken == _wcsb || payToken == _mira, "InvalidPayToken");
        _;
    }

    modifier validDeadline(uint256 deadline) {
        require(deadline > _now(), "InvalidDeadline");
        _;
    }

    modifier validPrice(uint256 price) {
        require(price > 0, "InvalidPrice");
        _;
    }

    /// @inheritdoc IMarketPlace
    function initialize(address wcsb_, address mira_) external override initializer {
        _wcsb = wcsb_;
        _mira = mira_;
    }

    /// @inheritdoc IMarketPlace
    function ask(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        askNotExists(nftAddress, tokenId, _msgSender())
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        require(IERC165(nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");
        require(IERC721(nftAddress).ownerOf(tokenId) == _msgSender(), "NotERC721TokenOwner");

        // save sell order
        _askOrders[nftAddress][tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            nftAddress,
            tokenId,
            payToken,
            price,
            deadline
        );

        emit Events.AskCreated(_msgSender(), nftAddress, tokenId, payToken, price, deadline);
    }

    /// @inheritdoc IMarketPlace
    function updateAsk(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        askExists(nftAddress, tokenId, _msgSender())
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        DataTypes.Order storage askOrder = _askOrders[nftAddress][tokenId][_msgSender()];
        // update ask order
        askOrder.payToken = payToken;
        askOrder.price = price;
        askOrder.deadline = deadline;

        emit Events.AskUpdated(_msgSender(), nftAddress, tokenId, payToken, price, deadline);
    }

    /// @inheritdoc IMarketPlace
    function cancelAsk(
        address nftAddress,
        uint256 tokenId
    ) external override askExists(nftAddress, tokenId, _msgSender()) {
        delete _askOrders[nftAddress][tokenId][_msgSender()];

        emit Events.AskCanceled(_msgSender(), nftAddress, tokenId);
    }

    /// @inheritdoc IMarketPlace
    function acceptAsk(
        address nftAddress,
        uint256 tokenId,
        address user
    ) external payable override nonReentrant validAsk(nftAddress, tokenId, user) {
        DataTypes.Order memory askOrder = _askOrders[nftAddress][tokenId][user];

        (address royaltyReceiver, uint256 royaltyAmount) = _royaltyInfo(
            nftAddress,
            tokenId,
            askOrder.price
        );

        if (askOrder.payToken == _wcsb) {
            // pay CSB
            _payCSBWithRoyalty(askOrder.owner, askOrder.price, royaltyReceiver, royaltyAmount);
        } else {
            // pay ERC20
            _payERC20WithRoyalty(
                _msgSender(),
                askOrder.owner,
                askOrder.payToken,
                askOrder.price,
                royaltyReceiver,
                royaltyAmount
            );
        }

        // transfer nft
        IERC721(nftAddress).safeTransferFrom(user, _msgSender(), tokenId);

        emit Events.AskMatched(
            askOrder.owner,
            nftAddress,
            tokenId,
            _msgSender(),
            askOrder.payToken,
            askOrder.price,
            royaltyReceiver,
            royaltyAmount
        );

        delete _askOrders[nftAddress][tokenId][user];
    }

    /// @inheritdoc IMarketPlace
    function bid(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        bidNotExists(nftAddress, tokenId, _msgSender())
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        require(IERC165(nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");

        // save buy order
        _bidOrders[nftAddress][tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            nftAddress,
            tokenId,
            payToken,
            price,
            deadline
        );

        emit Events.BidCreated(_msgSender(), nftAddress, tokenId, payToken, price, deadline);
    }

    /// @inheritdoc IMarketPlace
    function cancelBid(
        address nftAddress,
        uint256 tokenId
    ) external override bidExists(nftAddress, tokenId, _msgSender()) {
        delete _bidOrders[nftAddress][tokenId][_msgSender()];

        emit Events.BidCanceled(_msgSender(), nftAddress, tokenId);
    }

    /// @inheritdoc IMarketPlace
    function updateBid(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        validBid(nftAddress, tokenId, _msgSender())
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        DataTypes.Order storage bidOrder = _bidOrders[nftAddress][tokenId][_msgSender()];
        // update buy order
        bidOrder.payToken = payToken;
        bidOrder.price = price;
        bidOrder.deadline = deadline;

        emit Events.BidUpdated(_msgSender(), nftAddress, tokenId, payToken, price, deadline);
    }

    /// @inheritdoc IMarketPlace
    function acceptBid(
        address nftAddress,
        uint256 tokenId,
        address user
    ) external override nonReentrant validBid(nftAddress, tokenId, user) {
        DataTypes.Order memory bidOrder = _bidOrders[nftAddress][tokenId][user];

        (address royaltyReceiver, uint256 royaltyAmount) = _royaltyInfo(
            nftAddress,
            tokenId,
            bidOrder.price
        );
        // pay to msg.sender
        _payERC20WithRoyalty(
            bidOrder.owner,
            _msgSender(),
            bidOrder.payToken,
            bidOrder.price,
            royaltyReceiver,
            royaltyAmount
        );
        // transfer nft
        IERC721(nftAddress).safeTransferFrom(_msgSender(), user, tokenId);

        emit Events.BidMatched(
            bidOrder.owner,
            nftAddress,
            tokenId,
            _msgSender(),
            bidOrder.payToken,
            bidOrder.price,
            royaltyReceiver,
            royaltyAmount
        );

        delete _bidOrders[nftAddress][tokenId][user];
    }

    /// @inheritdoc IMarketPlace
    function getAskOrder(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view override returns (DataTypes.Order memory) {
        return _askOrders[nftAddress][tokenId][owner];
    }

    /// @inheritdoc IMarketPlace
    function getBidOrder(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view override returns (DataTypes.Order memory) {
        return _bidOrders[nftAddress][tokenId][owner];
    }

    /// @inheritdoc IMarketPlace
    function wcsb() external view override returns (address) {
        return _wcsb;
    }

    /// @inheritdoc IMarketPlace
    function mira() external view override returns (address) {
        return _mira;
    }

    function _payCSBWithRoyalty(
        address to,
        uint256 amount,
        address royaltyReceiver,
        uint256 royaltyAmount
    ) internal {
        require(msg.value >= amount, "NotEnoughFunds");
        // pay CSB
        if (royaltyReceiver != address(0)) {
            // slither-disable-next-line arbitrary-send-eth
            payable(royaltyReceiver).transfer(royaltyAmount);
            // slither-disable-next-line arbitrary-send-eth
            payable(to).transfer(amount - royaltyAmount);
        } else {
            // slither-disable-next-line arbitrary-send-eth
            payable(to).transfer(amount);
        }
    }

    function _payERC20WithRoyalty(
        address from,
        address to,
        address token,
        uint256 amount,
        address royaltyReceiver,
        uint256 royaltyAmount
    ) internal {
        // pay ERC20
        if (royaltyReceiver != address(0)) {
            IERC20(token).safeTransferFrom(from, royaltyReceiver, royaltyAmount);
            IERC20(token).safeTransferFrom(from, to, amount - royaltyAmount);
        } else {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }

    function _royaltyInfo(
        address nftAddress,
        uint256 tokenId,
        uint256 salePrice
    ) internal view returns (address royaltyReceiver, uint256 royaltyAmount) {
        if (IERC165(nftAddress).supportsInterface(type(IERC2981).interfaceId)) {
            (royaltyReceiver, royaltyAmount) = IERC2981(nftAddress).royaltyInfo(tokenId, salePrice);
        }
    }

    function _now() internal view virtual returns (uint256) {
        // slither-disable-next-line timestamp
        return block.timestamp;
    }
}
