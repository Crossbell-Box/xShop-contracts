// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ISwap {
    /**
     * @notice Initializes the MarketPlace, setting the WCSB contract address.
     * @param wcsb_ The address of WCSB contract.
     * @param mira_ The address of MIRA contract.
     * @param minMira_ The minimum amount of MIRA to sell.
     * @param minCsb_ The minimum amount of CSB to sell.
     */
    function initialize(address wcsb_, address mira_, uint256 minMira_, uint256 minCsb_) external;

    /**
     * @notice Sells MIRA for CSB.
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
     * @param expectedMiraAmount The expected amount of MIRA to receive.
     * @return orderId The new created order id.
     */
    function sellCSB(uint256 expectedMiraAmount) external payable returns (uint256 orderId);

    /**
     * @notice Cancels a sell order.
     * @param orderId The order id to cancel.
     */
    function cancelOrder(uint256 orderId) external;

    /**
     * @notice Accepts a sell order.
     * @param orderId The order id to accept.
     */
    function acceptOrder(uint256 orderId) external payable;

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
