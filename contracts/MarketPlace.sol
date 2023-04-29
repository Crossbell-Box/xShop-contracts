// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IMarketPlace} from "./interfaces/IMarketPlace.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Events} from "./libraries/Events.sol";
import {MarketPlaceStorage} from "./storage/MarketPlaceStorage.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC777} from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {IERC1820Registry} from "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract MarketPlace is
    IMarketPlace,
    Context,
    ReentrancyGuard,
    Initializable,
    IERC777Recipient,
    Pausable,
    AccessControlEnumerable,
    MarketPlaceStorage
{
    using SafeERC20 for IERC20;

    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC1820Registry public constant ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

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

    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IMarketPlace
    function initialize(address wcsb_, address mira_, address admin) external override initializer {
        _wcsb = wcsb_;
        _mira = mira_;

        // register interfaces
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );

        // grants `ADMIN_ROLE`
        _setupRole(ADMIN_ROLE, admin);
    }

    /// @inheritdoc IMarketPlace
    function pause() external override whenNotPaused onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @inheritdoc IMarketPlace
    function unpause() external override whenPaused onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account `to` (this contract). <br>
     *
     * Users can directly send MIRA tokens to this contract to accept an ask order,
     * the `tokensReceived` method will be called by MIRA token.
     * The userData/operatorData should be an abi encoded bytes of `uint256`,
     * which represents `orderId` of the ask order.
     */
    /// @inheritdoc IERC777Recipient
    function tokensReceived(
        address,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override(IERC777Recipient) {
        require(_msgSender() == _mira, "InvalidToken");
        require(address(this) == to, "InvalidReceiver");

        bytes memory data = userData.length > 0 ? userData : operatorData;
        // abi encoded bytes of uint256 `orderId`
        uint256 orderId = abi.decode(data, (uint256));
        _acceptAsk(orderId, from, amount);
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
        whenNotPaused
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
        returns (uint256 orderId)
    {
        require(IERC165(nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");
        require(IERC721(nftAddress).ownerOf(tokenId) == _msgSender(), "NotERC721TokenOwner");
        require(_askOrderIds[nftAddress][tokenId][_msgSender()] == 0, "AskExists");

        unchecked {
            orderId = ++_askOrderCount;
        }

        // save sell order
        _askOrderIds[nftAddress][tokenId][_msgSender()] = orderId;
        _askOrders[orderId] = DataTypes.Order(
            _msgSender(),
            nftAddress,
            tokenId,
            payToken,
            price,
            deadline
        );

        emit Events.AskCreated(
            orderId,
            _msgSender(),
            nftAddress,
            tokenId,
            payToken,
            price,
            deadline
        );
    }

    /// @inheritdoc IMarketPlace
    function updateAsk(
        uint256 orderId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        whenNotPaused
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        DataTypes.Order storage order = _askOrders[orderId];
        require(order.owner == _msgSender(), "NotAskOwnerOrNotExists");

        // update ask order
        order.payToken = payToken;
        order.price = price;
        order.deadline = deadline;

        emit Events.AskUpdated(orderId, payToken, price, deadline);
    }

    /// @inheritdoc IMarketPlace
    function cancelAsk(uint256 orderId) external override {
        DataTypes.Order storage order = _askOrders[orderId];
        require(order.owner == _msgSender(), "NotAskOwnerOrNotExists");

        // delete ask order
        delete _askOrderIds[order.nftAddress][order.tokenId][_msgSender()];
        delete _askOrders[orderId];

        emit Events.AskCanceled(orderId);
    }

    /// @inheritdoc IMarketPlace
    function acceptAsk(uint256 orderId) external payable override nonReentrant whenNotPaused {
        _acceptAsk(orderId, _msgSender(), 0);
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
        whenNotPaused
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
        returns (uint256 orderId)
    {
        require(IERC165(nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");
        require(_bidOrderIds[nftAddress][tokenId][_msgSender()] == 0, "BidExists");

        // save buy order
        unchecked {
            orderId = ++_bidOrderCount;
        }
        _bidOrderIds[nftAddress][tokenId][_msgSender()] = orderId;
        _bidOrders[orderId] = DataTypes.Order(
            _msgSender(),
            nftAddress,
            tokenId,
            payToken,
            price,
            deadline
        );

        emit Events.BidCreated(
            orderId,
            _msgSender(),
            nftAddress,
            tokenId,
            payToken,
            price,
            deadline
        );
    }

    /// @inheritdoc IMarketPlace
    function cancelBid(uint256 orderId) external override {
        DataTypes.Order storage order = _bidOrders[orderId];
        require(order.owner == _msgSender(), "NotBidOwnerOrNotExists");

        // delete order
        delete _bidOrderIds[order.nftAddress][order.tokenId][_msgSender()];
        delete _bidOrders[orderId];

        emit Events.BidCanceled(orderId);
    }

    /// @inheritdoc IMarketPlace
    function updateBid(
        uint256 orderId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        whenNotPaused
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        DataTypes.Order storage order = _bidOrders[orderId];
        require(order.owner == _msgSender(), "NotBidOwnerOrNotExists");

        // update buy order
        order.payToken = payToken;
        order.price = price;
        order.deadline = deadline;

        emit Events.BidUpdated(orderId, payToken, price, deadline);
    }

    /// @inheritdoc IMarketPlace
    function acceptBid(uint256 orderId) external override nonReentrant whenNotPaused {
        DataTypes.Order memory order = _bidOrders[orderId];
        // validate order
        require(order.deadline >= _now(), "BidExpiredOrNotExists");

        // delete order
        delete _bidOrderIds[order.nftAddress][order.tokenId][order.owner];
        delete _bidOrders[orderId];

        (address royaltyReceiver, uint256 royaltyAmount) = _royaltyInfo(
            order.nftAddress,
            order.tokenId,
            order.price
        );

        // pay to msg.sender
        _payERC20WithRoyalty(
            order.owner,
            _msgSender(),
            order.payToken,
            order.price,
            royaltyReceiver,
            royaltyAmount
        );
        // transfer nft
        IERC721(order.nftAddress).safeTransferFrom(_msgSender(), order.owner, order.tokenId);

        emit Events.BidMatched(
            orderId,
            order.owner,
            _msgSender(),
            order.nftAddress,
            order.tokenId,
            order.payToken,
            order.price,
            royaltyReceiver,
            royaltyAmount
        );
    }

    /// @inheritdoc IMarketPlace
    function getAskOrder(uint256 orderId) external view override returns (DataTypes.Order memory) {
        return _askOrders[orderId];
    }

    /// @inheritdoc IMarketPlace
    function getBidOrder(uint256 orderId) external view override returns (DataTypes.Order memory) {
        return _bidOrders[orderId];
    }

    /// @inheritdoc IMarketPlace
    function getAskOrderId(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view override returns (uint256 orderId) {
        return _askOrderIds[nftAddress][tokenId][owner];
    }

    /// @inheritdoc IMarketPlace
    function getBidOrderId(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view override returns (uint256 orderId) {
        return _bidOrderIds[nftAddress][tokenId][owner];
    }

    /// @inheritdoc IMarketPlace
    function wcsb() external view override returns (address) {
        return _wcsb;
    }

    /// @inheritdoc IMarketPlace
    function mira() external view override returns (address) {
        return _mira;
    }

    function _pay(
        address from,
        address to,
        address payToken,
        uint256 amount,
        address royaltyReceiver,
        uint256 royaltyAmount,
        uint256 erc777Amount
    ) internal {
        if (payToken == _wcsb) {
            // pay CSB
            _payCSBWithRoyalty(to, amount, royaltyReceiver, royaltyAmount);
        } else if (erc777Amount > 0) {
            // pay ERC777
            _payERC777WithRoyalty(
                to,
                payToken,
                amount,
                royaltyReceiver,
                royaltyAmount,
                erc777Amount
            );
        } else {
            // pay ERC20
            _payERC20WithRoyalty(from, to, payToken, amount, royaltyReceiver, royaltyAmount);
        }
    }

    function _acceptAsk(
        uint256 orderId,
        address buyer,
        uint256 erc777Amount
    ) internal whenNotPaused {
        DataTypes.Order memory askOrder = _askOrders[orderId];
        require(askOrder.deadline >= _now(), "AskExpiredOrNotExists");

        // delete ask order
        delete _askOrderIds[askOrder.nftAddress][askOrder.tokenId][askOrder.owner];
        delete _askOrders[orderId];

        (address royaltyReceiver, uint256 royaltyAmount) = _royaltyInfo(
            askOrder.nftAddress,
            askOrder.tokenId,
            askOrder.price
        );

        // pay tokens
        _pay(
            buyer,
            askOrder.owner,
            askOrder.payToken,
            askOrder.price,
            royaltyReceiver,
            royaltyAmount,
            erc777Amount
        );

        // transfer nft
        IERC721(askOrder.nftAddress).safeTransferFrom(askOrder.owner, buyer, askOrder.tokenId);

        emit Events.AskMatched(
            orderId,
            askOrder.owner,
            buyer,
            askOrder.nftAddress,
            askOrder.tokenId,
            askOrder.payToken,
            askOrder.price,
            royaltyReceiver,
            royaltyAmount
        );
    }

    function _payCSBWithRoyalty(
        address to,
        uint256 amount,
        address royaltyReceiver,
        uint256 royaltyAmount
    ) internal {
        require(msg.value >= amount, "NotEnoughCSBFunds");
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

    function _payERC777WithRoyalty(
        address to,
        address token,
        uint256 amount,
        address royaltyReceiver,
        uint256 royaltyAmount,
        uint256 erc777Amount
    ) internal {
        require(erc777Amount >= amount, "NotEnoughERC777Funds");
        // pay ERC777
        if (royaltyReceiver != address(0)) {
            IERC20(token).safeTransfer(royaltyReceiver, royaltyAmount);
            IERC20(token).safeTransfer(to, amount - royaltyAmount);
        } else {
            IERC20(token).safeTransfer(to, amount);
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
        if (IERC165(nftAddress).supportsInterface(INTERFACE_ID_ERC2981)) {
            (royaltyReceiver, royaltyAmount) = IERC2981(nftAddress).royaltyInfo(tokenId, salePrice);
        }
    }

    function _now() internal view virtual returns (uint256) {
        // slither-disable-next-line timestamp
        return block.timestamp;
    }
}
