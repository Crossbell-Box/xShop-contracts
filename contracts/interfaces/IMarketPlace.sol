// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IMarketPlace {
    function initialize(address web3Entry_, address wcsb_) external;

    /**
     * @notice Sets the royalty.
     * @param characterId The character ID of note.
     * @param noteId The note ID of note.
     * @param receiver The address receiving the royalty.
     * @param percentage The percentage of the royalty. (multiply by 100, which means 10000 is 100 percent)
     */
    function setRoyalty(
        uint256 characterId,
        uint256 noteId,
        address receiver,
        uint256 percentage
    ) external;

    /**
     * @notice Creates an ask order for an NFT.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to be sold.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The sale price for the NFT.
     * @param deadline The expiration timestamp of the ask order.
     */
    function ask(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) external;

    /**
     * @notice Updates an ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param price The new sale price for the NFT.
     * @param deadline The new expiration timestamp of the ask order.
     */
    function updateAsk(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) external;

    /**
     * @notice Cancels an ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     */
    function cancelAsk(address nftAddress, uint256 tokenId) external;

    /**
     * @notice Accepts an ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param user The owner of ask order, as well as the  owner of the NFT.
     */
    function acceptAsk(address nftAddress, uint256 tokenId, address user) external payable;

    /**
     * @notice Creates a bid order for an NFT.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to bid.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The bid price for the NFT.
     * @param deadline The expiration timestamp of the bid order.
     */
    function bid(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) external;

    /**
     * @notice Cancels a bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     */
    function cancelBid(address nftAddress, uint256 tokenId) external;

    /**
     * @notice Updates a bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The new bid price for the NFT.
     * @param deadline The new expiration timestamp of the ask order.
     */
    function updateBid(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    ) external;

    /**
     * @notice Accepts a bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param user The owner of bid order.
     */
    function acceptBid(address nftAddress, uint256 tokenId, address user) external;

    /**
     * @notice Gets an ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to be sold.
     * @param owner The owner who creates the order.
     */
    function getAskOrder(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view returns (DataTypes.Order memory);

    /**
     * @notice Gets a bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to bid.
     * @param owner The owner who creates the order.
     */
    function getBidOrder(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view returns (DataTypes.Order memory);

    /**
     * @notice Returns the royalty according to a given nft token address.
     * @param token The nft token address to query with.
     * @return Royalty The royalty struct.
     */
    function getRoyalty(address token) external view returns (DataTypes.Royalty memory);
}
