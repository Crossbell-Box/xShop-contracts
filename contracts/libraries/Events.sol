// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library Events {
    /**
     * @notice Emitted when an ask order is created.
     * @param owner The owner of the ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to be sold.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The sale price for the NFT.
     * @param deadline The expiration timestamp of the ask order.
     */
    event AskCreated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when an ask order is updated.
     * @param owner The owner of the ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The new sale price for the NFT.
     * @param deadline The expiration timestamp of the ask order.
     */
    event AskUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when an ask order is canceled.
     * @param owner The owner of the ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     */
    event AskCanceled(address indexed owner, address indexed nftAddress, uint256 indexed tokenId);

    /**
     * @notice Emitted when a bid order is created.
     * @param owner The owner of the bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to bid.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The bid price for the NFT.
     * @param deadline The expiration timestamp of the bid order.
     */
    event BidCreated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when a bid  order is canceled.
     * @param owner The owner of the bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     */
    event BidCanceled(address indexed owner, address indexed nftAddress, uint256 indexed tokenId);

    /**
     * @notice Emitted when a bid order is updated.
     * @param owner The owner of the bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The new bid price for the NFT.
     * @param deadline The expiration timestamp of the bid order.
     */
    event BidUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when a bid/ask order is accepted(matched).
     * @param seller The seller, as well as the owner of nft.
     * @param buyer The buyer who wanted to paying ERC20 tokens for the nft.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The price the buyer will pay to the seller.
     * @param royaltyReceiver The receiver of the royalty fee.
     * @param feeAmount The amount of the royalty fee.
     */
    event OrdersMatched(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        address royaltyReceiver,
        uint256 feeAmount
    );
}
