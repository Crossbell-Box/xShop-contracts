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
     * The userData/operatorData should be an abi encoded bytes of `address`, `uint256`
     * and `address`,  which represents `nftAddress`, `tokenId` and `user` with total length 72.
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
        // abi encoded bytes of (nftAddress, tokenId, user)
        // slither-disable-next-line variable-scope
        (address nftAddress, uint256 tokenId, address user) = abi.decode(
            data,
            (address, uint256, address)
        );
        _acceptAsk(nftAddress, tokenId, user, from, amount);
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
        whenNotPaused
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
    ) external payable override nonReentrant whenNotPaused validAsk(nftAddress, tokenId, user) {
        _acceptAsk(nftAddress, tokenId, user, _msgSender(), 0);
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
        whenNotPaused
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
    ) external override nonReentrant whenNotPaused validBid(nftAddress, tokenId, user) {
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
        address nftAddress,
        uint256 tokenId,
        address user,
        address buyer,
        uint256 erc777Amount
    ) internal whenNotPaused {
        DataTypes.Order memory askOrder = _askOrders[nftAddress][tokenId][user];

        (address royaltyReceiver, uint256 royaltyAmount) = _royaltyInfo(
            nftAddress,
            tokenId,
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
        IERC721(nftAddress).safeTransferFrom(user, buyer, tokenId);

        emit Events.AskMatched(
            askOrder.owner,
            nftAddress,
            tokenId,
            buyer,
            askOrder.payToken,
            askOrder.price,
            royaltyReceiver,
            royaltyAmount
        );

        delete _askOrders[nftAddress][tokenId][user];
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
        require(erc777Amount >= amount, "NotEnougERC777Funds");
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
