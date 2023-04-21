// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ISwap} from "./interfaces/ISwap.sol";
import {Events} from "./libraries/Events.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC777} from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {IERC1820Registry} from "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Swap is
    ISwap,
    Context,
    IERC777Recipient,
    Initializable,
    ReentrancyGuard,
    Pausable,
    AccessControlEnumerable
{
    using SafeERC20 for IERC20;

    address internal _wcsb; //wrapped CSB.
    address internal _mira; // mira token address
    uint256 internal _minCsb; // minimum CSB amount to sell
    uint256 internal _minMira; // minimum MIRA amount to sell

    mapping(uint256 => DataTypes.SellOrder) internal _orders;
    uint256 internal _orderCount;

    uint8 public constant SELL_MIRA = 1;
    uint8 public constant SELL_CSB = 2;
    uint256 public constant OPERATION_TYPE_ACCEPT_ORDER = 1;
    uint256 public constant OPERATION_TYPE_SELL_MIRA = 2;

    IERC1820Registry public constant ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc ISwap
    function initialize(
        address mira_,
        uint256 minCsb_,
        uint256 minMira_,
        address admin
    ) external override initializer {
        _mira = mira_;

        _minCsb = minCsb_;
        _minMira = minMira_;

        // register interfaces
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );

        // grants `ADMIN_ROLE`
        _setupRole(ADMIN_ROLE, admin);
    }

    /// @inheritdoc ISwap
    function pause() external override whenNotPaused onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @inheritdoc ISwap
    function unpause() external override whenPaused onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account `to` (this contract). <br>
     *
     * The userData/operatorData should be an abi encoded bytes of two `uint256`,
     * the first uint256 represents operation type. <br>
     * opType = 1: accept an order.<br>
     * opType = 2: sell MIRA for CSB.
     * @param operator The address performing the send or mint operation.
     * @param from The address sending the tokens.
     * @param to The address of the recipient.
     * @param amount The amount of tokens being transferred.
     * @param userData The data provided by the token holder.
     * @param operatorData The data provided by the operator (if any).
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
        require(amount > 0, "InvalidAmount");

        bytes memory data = userData.length > 0 ? userData : operatorData;
        if (data.length > 0) {
            (uint256 opType, uint256 value) = abi.decode(data, (uint256, uint256));
            if (opType == OPERATION_TYPE_ACCEPT_ORDER) {
                // accept an order
                _acceptOrder(value, from, amount);
            } else if (opType == OPERATION_TYPE_SELL_MIRA) {
                // sell MIRA for CSB
                _sellMIRA(from, amount, value, true);
            } else {
                revert("InvalidData");
            }
        }
    }

    /// @inheritdoc ISwap
    function sellMIRA(
        uint256 miraAmount,
        uint256 expectedCsbAmount
    ) external override returns (uint256 orderId) {
        orderId = _sellMIRA(_msgSender(), miraAmount, expectedCsbAmount, false);
    }

    /// @inheritdoc ISwap
    function sellCSB(
        uint256 expectedMiraAmount
    ) external payable override whenNotPaused returns (uint256 orderId) {
        require(msg.value >= _minCsb, "InvalidCSBAmount");

        unchecked {
            orderId = ++_orderCount;
        }
        _orders[orderId] = DataTypes.SellOrder({
            owner: _msgSender(),
            orderType: SELL_CSB,
            miraAmount: expectedMiraAmount,
            csbAmount: msg.value
        });

        emit Events.SellCSB(_msgSender(), msg.value, expectedMiraAmount, orderId);
    }

    /// @inheritdoc ISwap
    function cancelOrder(uint256 orderId) external override nonReentrant {
        DataTypes.SellOrder memory order = _orders[orderId];
        require(order.owner == _msgSender(), "NotOrderOwner");

        delete _orders[orderId];

        if (order.orderType == SELL_MIRA) {
            IERC20(_mira).safeTransfer(order.owner, order.miraAmount);
        } else if (order.orderType == SELL_CSB) {
            payable(order.owner).transfer(order.csbAmount);
        }

        emit Events.SellOrderCanceled(orderId);
    }

    /// @inheritdoc ISwap
    function acceptOrder(uint256 orderId) external payable override {
        _acceptOrder(orderId, _msgSender(), 0);
    }

    /// @inheritdoc ISwap
    function getOrder(uint256 orderId) external view override returns (DataTypes.SellOrder memory) {
        return _orders[orderId];
    }

    /// @inheritdoc ISwap
    function mira() external view override returns (address) {
        return _mira;
    }

    function _sellMIRA(
        address owner,
        uint256 miraAmount,
        uint256 expectedCsbAmount,
        bool onTokensReceived
    ) internal nonReentrant whenNotPaused returns (uint256 orderId) {
        require(miraAmount >= _minMira, "InvalidMiraAmount");

        // create sell order
        unchecked {
            orderId = ++_orderCount;
        }
        _orders[orderId] = DataTypes.SellOrder({
            owner: owner,
            orderType: SELL_MIRA,
            miraAmount: miraAmount,
            csbAmount: expectedCsbAmount
        });

        // transfer MIRA to this contract
        if (!onTokensReceived) {
            IERC20(_mira).safeTransferFrom(owner, address(this), miraAmount);
        }

        emit Events.SellMIRA(owner, miraAmount, expectedCsbAmount, orderId);
    }

    // slither-disable-next-line arbitrary-send-eth
    function _acceptOrder(
        uint256 orderId,
        address buyer,
        uint256 erc777Amount
    ) internal nonReentrant whenNotPaused {
        DataTypes.SellOrder memory order = _orders[orderId];
        require(order.owner != address(0), "InvalidOrder");

        // delete order first
        delete _orders[orderId];

        // transfer tokens
        if (order.orderType == SELL_MIRA) {
            require(msg.value >= order.csbAmount, "InvalidCSBAmount");

            IERC20(_mira).safeTransfer(buyer, order.miraAmount);
            payable(order.owner).transfer(order.csbAmount);
        } else if (order.orderType == SELL_CSB) {
            // transfer MIRA to order owner
            if (erc777Amount > 0) {
                require(erc777Amount >= order.miraAmount, "InvalidMiraAmount");
                IERC20(_mira).safeTransfer(order.owner, order.miraAmount);
            } else {
                IERC20(_mira).safeTransferFrom(buyer, order.owner, order.miraAmount);
            }
            // transfer CSB to buyer
            payable(buyer).transfer(order.csbAmount);
        } else {
            revert("InvalidOrderType");
        }

        emit Events.SellOrderMatched(orderId, buyer);
    }
}
