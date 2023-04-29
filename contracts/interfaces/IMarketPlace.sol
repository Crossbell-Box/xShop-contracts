// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IMarketPlace {
    /**
     * @notice Initializes the MarketPlace, setting the WCSB contract address.
     * @param wcsb_ The address of WCSB contract.
     * @param mira_ The address of MIRA contract.
     * @param admin The address of the contract admin.
     */
    function initialize(address wcsb_, address mira_, address admin) external;

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
     * @notice Creates an ask order for an NFT.
     * Emits the `AskCreated` event.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to be sold.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The sale price for the NFT.
     * @param deadline The expiration timestamp of the ask order.
     * @return orderId The id of the new generated ask order.
     */
    function ask(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) external returns (uint256 orderId);

    /**
     * @notice Updates an ask order.
     * Emits the `AskUpdated` event.
     * @param orderId The id of the ask order to be updated.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The new sale price for the NFT.
     * @param deadline The new expiration timestamp of the ask order.
     */
    function updateAsk(uint256 orderId, address payToken, uint256 price, uint256 deadline) external;

    /**
     * @notice Cancels an ask order.
     * Emits the `AskCanceled` event.
     * @param orderId The id of the ask order to be canceled.
     */
    function cancelAsk(uint256 orderId) external;

    /**
     * @notice Accepts an ask order.
     * Emits the `OrdersMatched` event.
     * @dev The amount of CSB to send must be specified in the `msg.value`.
     * @param orderId The id of the ask order to be accepted.
     */
    function acceptAsk(uint256 orderId) external payable;

    /**
     * @notice Creates a bid order for an NFT.
     * Emits the `BidCreated` event.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to bid.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The bid price for the NFT.
     * @param deadline The expiration timestamp of the bid order.
     * @return orderId The id of the new generated bid order.
     */
    function bid(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) external returns (uint256 orderId);

    /**
     * @notice Cancels a bid order.
     * Emits the `BidCanceled` event.
     * @param orderId The id of the bid order to be canceled.
     */
    function cancelBid(uint256 orderId) external;

    /**
     * @notice Updates a bid order.
     * Emits the `BidUpdated` event.
     * @param orderId The id of the bid order to be updated.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The new bid price for the NFT.
     * @param deadline The new expiration timestamp of the ask order.
     */
    function updateBid(uint256 orderId, address payToken, uint256 price, uint256 deadline) external;

    /**
     * @notice Accepts a bid order.
     * Emits the `OrdersMatched` event.
     * @param orderId The id of the bid order to be accepted.
     */
    function acceptBid(uint256 orderId) external;

    /**
     * @notice Gets the detail info of an ask order.
     * @param orderId The id of the ask order to query.
     */
    function getAskOrder(uint256 orderId) external view returns (DataTypes.Order memory);

    /**
     * @notice Gets the detail info of a bid order.
     * @param orderId The id of the bid order to query.
     */
    function getBidOrder(uint256 orderId) external view returns (DataTypes.Order memory);

    /**
     * @notice Gets ID of an ask order .
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to be sold.
     * @param owner The owner who creates the order.
     */
    function getAskOrderId(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view returns (uint256 orderId);

    /**
     * @notice Gets ID of a bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to bid.
     * @param owner The owner who creates the order.
     */
    function getBidOrderId(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view returns (uint256 orderId);

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
