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

    function sellMIRA(
        uint256 miraAmount,
        uint256 expectedCsbAmount
    ) external returns (uint256 orderId);

    function sellCSB(uint256 expectedMiraAmount) external payable returns (uint256 orderId);

    function cancelOrder(uint256 orderId) external;

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
