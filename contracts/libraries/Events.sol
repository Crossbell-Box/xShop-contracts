// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library Events {
    /**
     * @notice Emitted when an ask order is created.
     * @param orderId The id of the new generated ask order.
     * @param owner The owner of the ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to be sold.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The sale price for the NFT.
     * @param deadline The expiration timestamp of the ask order.
     */
    event AskCreated(
        uint256 indexed orderId,
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when an ask order is updated.
     * @param orderId The id of the ask order.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The new sale price for the NFT.
     * @param deadline The expiration timestamp of the ask order.
     */
    event AskUpdated(uint256 indexed orderId, address payToken, uint256 price, uint256 deadline);

    /**
     * @notice Emitted when an ask order is canceled.
     * @param orderId The id of the ask order.
     */
    event AskCanceled(uint256 orderId);

    /**
     * @notice Emitted when a bid order is created.
     * @param orderId The id of the new generated bid order.
     * @param owner The owner of the bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to bid.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The bid price for the NFT.
     * @param deadline The expiration timestamp of the bid order.
     */
    event BidCreated(
        uint256 indexed orderId,
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when a bid order is canceled.
     * @param orderId The id of the bid order.
     */
    event BidCanceled(uint256 indexed orderId);

    /**
     * @notice Emitted when a bid order is updated.
     * @param orderId The id of the bid order.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The new bid price for the NFT.
     * @param deadline The expiration timestamp of the bid order.
     */
    event BidUpdated(uint256 indexed orderId, address payToken, uint256 price, uint256 deadline);

    /**
     * @notice Emitted when a ask order is accepted(matched).
     * @param orderId The id of the ask order.
     * @param owner The the owner of the ask order, as well as the owner who wants to sell the nft.
     * @param buyer The buyer who wanted to paying ERC20 tokens for the nft.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The price the buyer will pay to the seller.
     * @param royaltyReceiver The receiver of the royalty fee.
     * @param royaltyAmount The amount of the royalty fee.
     */
    event AskMatched(
        uint256 indexed orderId,
        address indexed owner,
        address indexed buyer,
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyAmount
    );

    /**
     * @notice Emitted when a bid order is accepted(matched).
     * @param orderId The id of the bid order.
     * @param owner The owner of the bid order,
     * as well as the buyer who wanted to paying ERC20 tokens for the nft.
     * @param seller The seller, as well as the owner who wants to sell the nft.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The price the buyer will pay to the seller.
     * @param royaltyReceiver The receiver of the royalty fee.
     * @param royaltyAmount The amount of the royalty fee.
     */
    event BidMatched(
        uint256 indexed orderId,
        address indexed owner,
        address indexed seller,
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyAmount
    );

    event SellMIRA(
        address indexed owner,
        uint256 indexed miraAmount,
        uint256 indexed csbAmount,
        uint256 orderId
    );

    event SellCSB(
        address indexed owner,
        uint256 indexed csbAmount,
        uint256 indexed miraAmount,
        uint256 orderId
    );

    event SellOrderCanceled(uint256 indexed orderId);

    event SellOrderMatched(uint256 indexed orderId, address indexed buyer);
}
