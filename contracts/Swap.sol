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

contract Swap is ISwap, Context, IERC777Recipient, Initializable {
    using SafeERC20 for IERC20;

    address internal _wcsb; //wrapped CSB.
    address internal _mira; // mira token address
    uint256 internal _minMira; // minimum MIRA amount to sell
    uint256 internal _minCsb; // minimum CSB amount to sell

    uint8 public constant SELL_MIRA = 1;
    uint8 public constant SELL_CSB = 2;

    IERC1820Registry public constant ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    mapping(uint256 => DataTypes.SellOrder) internal _orders;
    uint256 internal _orderCount;

    /// @inheritdoc ISwap
    function initialize(
        address wcsb_,
        address mira_,
        uint256 minMira_,
        uint256 minCsb_
    ) external override initializer {
        _wcsb = wcsb_;
        _mira = mira_;

        _minMira = minMira_;
        _minCsb = minCsb_;

        // register interfaces
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
    }

    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account `to` (this contract). <br>
     *
     * The userData/operatorData should be an abi encoded bytes of two `uint256`,
     * the first uint256 represents operation type. <br>
     * opType = 1: accept an order.<br>
     * opType = 2: sell MIRA for CSB.
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
        (uint256 opType, uint256 value) = abi.decode(data, (uint256, uint256));
        if (opType == 1) {
            // accept an order
            _acceptOrder(value, from, amount);
        } else if (opType == 2) {
            // sell MIRA for CSB
            _sellMIRA(from, amount, value);
        } else {
            revert("InvalidData");
        }
    }

    /// @inheritdoc ISwap
    function sellMIRA(
        uint256 miraAmount,
        uint256 expectedCsbAmount
    ) external override returns (uint256 orderId) {
        orderId = _sellMIRA(_msgSender(), miraAmount, expectedCsbAmount);
    }

    function _sellMIRA(
        address owner,
        uint256 miraAmount,
        uint256 expectedCsbAmount
    ) internal returns (uint256 orderId) {
        require(miraAmount >= _minMira, "InvalidMiraAmount");

        IERC20(_mira).safeTransferFrom(owner, address(this), miraAmount);

        unchecked {
            orderId = ++_orderCount;
        }
        _orders[orderId] = DataTypes.SellOrder({
            owner: owner,
            orderType: SELL_MIRA,
            miraAmount: miraAmount,
            csbAmount: expectedCsbAmount
        });

        emit Events.SellMIRA(owner, miraAmount, expectedCsbAmount, orderId);
    }

    /// @inheritdoc ISwap
    function sellCSB(
        uint256 expectedMiraAmount
    ) external payable override returns (uint256 orderId) {
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
    function cancelOrder(uint256 orderId) external override {
        require(_orders[orderId].owner == _msgSender(), "NotOrderOwner");

        delete _orders[orderId];

        emit Events.SellOrderCanceled(orderId);
    }

    /// @inheritdoc ISwap
    function acceptOrder(uint256 orderId) external payable override {
        _acceptOrder(orderId, _msgSender(), 0);
    }

    /// @inheritdoc ISwap
    function wcsb() external view override returns (address) {
        return _wcsb;
    }

    /// @inheritdoc ISwap
    function mira() external view override returns (address) {
        return _mira;
    }

    function _acceptOrder(uint256 orderId, address buyer, uint256 erc777Amount) internal {
        DataTypes.SellOrder memory order = _orders[orderId];
        if (order.orderType == SELL_MIRA) {
            require(msg.value >= order.csbAmount, "InvalidCSBAmount");

            // transfer tokens
            IERC20(_mira).safeTransfer(buyer, order.miraAmount);
            payable(order.owner).transfer(order.csbAmount);
        } else if (order.orderType == SELL_CSB) {
            if (erc777Amount > 0) {
                require(erc777Amount >= order.miraAmount, "InvalidMiraAmount");
            }
            // transfer tokens
            payable(buyer).transfer(order.csbAmount);
            IERC20(_mira).safeTransfer(order.owner, order.miraAmount);
        } else {
            revert("InvalidOrderType");
        }

        delete _orders[orderId];

        emit Events.SellOrderMatched(orderId, buyer);
    }
}
