// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {DataTypes} from "../libraries/DataTypes.sol";

interface ISwap {
    /**
     * @notice Initializes the MarketPlace, setting the WCSB contract address.
     * @param wcsb_ The address of WCSB contract.
     * @param mira_ The address of MIRA contract.
     * @param minCsb_ The minimum amount of CSB to sell.
     * @param minMira_ The minimum amount of MIRA to sell.
     * @param admin The address of the contract admin.
     */
    function initialize(
        address wcsb_,
        address mira_,
        uint256 minCsb_,
        uint256 minMira_,
        address admin
    ) external;

    /**
     * @notice Pauses interaction with the contract.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     */
    function pause() external;

    /**
     * @notice Resumes interaction with the contract.
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     */
    function unpause() external;

    /**
     * @notice Sells MIRA for CSB.
     * Creates a SellOrder and emits the `SellMIRA` event.
     * @param miraAmount The amount of MIRA to sell.
     * @param expectedCsbAmount The expected amount of CSB to receive.
     * @return orderId The new created order id.
     */
    function sellMIRA(
        uint256 miraAmount,
        uint256 expectedCsbAmount
    ) external returns (uint256 orderId);

    /**
     * @notice Sells CSB for MIRA.
     * Creates a SellOrder and emits the `SellCSB` event.
     * @dev The amount of CSB to sell must be specified in the `msg.value`.<br>
     * @param expectedMiraAmount The expected amount of MIRA to receive.
     * @return orderId The new created order id.
     */
    function sellCSB(uint256 expectedMiraAmount) external payable returns (uint256 orderId);

    /**
     * @notice Cancels a sell order and refunds to the seller.
     * Deletes a given SellOrder and emits the `SellOrderCanceled` event.
     * @param orderId The order id to cancel.
     */
    function cancelOrder(uint256 orderId) external;

    /**
     * @notice Accepts a sell order and transfers the tokens to the traders.
     * Deletes a given SellOrder and emits the `SellOrderMatched` event.
     * @param orderId The order id to accept.
     */
    function acceptOrder(uint256 orderId) external payable;

    /**
     * @notice Returns the SellOrder struct of a given order id.
     * @param orderId The order id to get.
     * @return order The SellOrder struct.
     */
    function getOrder(uint256 orderId) external view returns (DataTypes.SellOrder memory);

    /**
     * @notice Returns the address of WCSB contract.
     * @return The address of WCSB contract.
     */
    function wcsb() external view returns (address);

    /**
     * @notice Returns the address of MIRA contract.
     * @return The address of MIRA contract.
     */
    function mira() external view returns (address);
}
