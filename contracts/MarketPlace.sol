// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IMarketPlace.sol";
import "./interfaces/IWeb3Entry.sol";
import "./libraries/DataTypes.sol";
import "./libraries/Constants.sol";
import "./libraries/Events.sol";
import "./storage/MarketPlaceStorage.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketPlace is IMarketPlace, Context, ReentrancyGuard, Initializable, MarketPlaceStorage {
    using SafeERC20 for IERC20;

    uint256 internal constant REVISION = 1;
    bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    modifier askNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][_user];
        require(askOrder.deadline == 0, "AskExists");
        _;
    }

    modifier askExists(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][_user];
        require(askOrder.deadline > 0, "AskNotExists");
        _;
    }

    modifier validAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][_user];
        require(askOrder.deadline >= _now(), "AskExpiredOrNotExists");
        _;
    }

    modifier bidNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][_user];
        require(bidOrder.deadline == 0, "BidExists");
        _;
    }

    modifier bidExists(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][_user];
        require(bidOrder.deadline > 0, "BidNotExists");
        _;
    }

    modifier validBid(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][_user];
        require(bidOrder.deadline != 0, "BidNotExists");
        require(bidOrder.deadline >= _now(), "BidExpired");
        _;
    }

    modifier validPayToken(address _payToken) {
        require(_payToken == WCSB || _payToken == Constants.NATIVE_CSB, "InvalidPayToken");
        _;
    }

    modifier validDeadline(uint256 _deadline) {
        require(_deadline > _now(), "InvalidDeadline");
        _;
    }

    modifier validPrice(uint256 _price) {
        require(_price > 0, "InvalidPrice");
        _;
    }

    /**
     * @notice Initializes the MarketPlace, setting the initial web3Entry address and WCSB address.
     * @param _web3Entry The address of web3Entry.
     * @param _wcsb The address of WCSB.
     */
    function initialize(address _web3Entry, address _wcsb) external initializer {
        web3Entry = _web3Entry;
        WCSB = _wcsb;
    }

    /**
     * @notice Returns the royalty according to a given nft token address.
     * @param token The nft token address to query with.
     * @return Royalty The royalty struct.
     */
    function getRoyalty(address token) external view returns (DataTypes.Royalty memory) {
        return royalties[token];
    }

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
    ) external {
        require(percentage <= Constants.MAX_ROYALTY, "InvalidPercentage");
        // check character owner
        require(msg.sender == IERC721(web3Entry).ownerOf(characterId), "NotCharacterOwner");

        // check mintNFT address
        DataTypes.Note memory note = IWeb3Entry(web3Entry).getNote(characterId, noteId);
        require(note.mintNFT != address(0), "NoMintNFT");

        // set royalty
        royalties[note.mintNFT].receiver = receiver;
        royalties[note.mintNFT].percentage = percentage;

        emit Events.RoyaltySet(msg.sender, note.mintNFT, receiver, percentage);
    }

    /**
     * @notice Creates an ask order for an NFT.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT to be sold.
     * @param _payToken The ERC20 token address for buyers to pay.
     * @param _price The sale price for the NFT.
     * @param _deadline The expiration timestamp of the ask order.
     */
    function ask(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    )
        external
        askNotExists(_nftAddress, _tokenId, _msgSender())
        validPayToken(_payToken)
        validDeadline(_deadline)
        validPrice(_price)
    {
        require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");
        require(IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender(), "NotERC721TokenOwner");

        // save sell order
        askOrders[_nftAddress][_tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _price,
            _deadline
        );

        emit Events.AskCreated(_msgSender(), _nftAddress, _tokenId, WCSB, _price, _deadline);
    }

    /**
     * @notice Updates an ask order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     * @param _price The new sale price for the NFT.
     * @param _deadline The new expiration timestamp of the ask order.
     */
    function updateAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    )
        external
        askExists(_nftAddress, _tokenId, _msgSender())
        validPayToken(_payToken)
        validDeadline(_deadline)
        validPrice(_price)
    {
        DataTypes.Order storage askOrder = askOrders[_nftAddress][_tokenId][_msgSender()];
        // update ask order
        askOrder.payToken = _payToken;
        askOrder.price = _price;
        askOrder.deadline = _deadline;

        emit Events.AskUpdated(_msgSender(), _nftAddress, _tokenId, _payToken, _price, _deadline);
    }

    /**
     * @notice Cancels an ask order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     */
    function cancelAsk(address _nftAddress, uint256 _tokenId)
        external
        askExists(_nftAddress, _tokenId, _msgSender())
    {
        delete askOrders[_nftAddress][_tokenId][_msgSender()];

        emit Events.AskCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    /**
     * @notice Accepts an ask order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     * @param _user The owner of ask order, as well as the  owner of the NFT.
     */
    function acceptAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) external payable nonReentrant validAsk(_nftAddress, _tokenId, _user) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][_user];

        DataTypes.Royalty memory royalty = royalties[askOrder.nftAddress];
        // pay to owner
        uint256 feeAmount = _payWithFee(
            _msgSender(),
            askOrder.owner,
            askOrder.payToken,
            askOrder.price,
            royalty.receiver,
            royalty.percentage
        );
        // transfer nft
        IERC721(_nftAddress).safeTransferFrom(_user, _msgSender(), _tokenId);

        emit Events.OrdersMatched(
            askOrder.owner,
            _msgSender(),
            _nftAddress,
            _tokenId,
            askOrder.payToken,
            askOrder.price,
            royalty.receiver,
            feeAmount
        );

        delete askOrders[_nftAddress][_tokenId][_user];
    }

    /**
     * @notice Creates an bid order for an NFT.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT to bid.
     * @param _payToken The ERC20 token address for buyers to pay.
     * @param _price The bid price for the NFT.
     * @param _deadline The expiration timestamp of the bid order.
     */
    function bid(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    )
        external
        bidNotExists(_nftAddress, _tokenId, _msgSender())
        validPayToken(_payToken)
        validDeadline(_deadline)
        validPrice(_price)
    {
        require(_payToken != Constants.NATIVE_CSB, "NativeCSBNotAllowed");
        require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");

        // save buy order
        bidOrders[_nftAddress][_tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _price,
            _deadline
        );

        emit Events.BidCreated(_msgSender(), _nftAddress, _tokenId, _payToken, _price, _deadline);
    }

    /**
     * @notice Cancels a bid order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     */
    function cancelBid(address _nftAddress, uint256 _tokenId)
        external
        bidExists(_nftAddress, _tokenId, _msgSender())
    {
        delete bidOrders[_nftAddress][_tokenId][_msgSender()];

        emit Events.BidCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    /**
     * @notice Updates a bid order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     * @param _payToken The ERC20 token address for buyers to pay.
     * @param _price The new bid price for the NFT.
     * @param _deadline The new expiration timestamp of the ask order.
     */
    function updateBid(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    )
        external
        validBid(_nftAddress, _tokenId, _msgSender())
        validPayToken(_payToken)
        validDeadline(_deadline)
        validPrice(_price)
    {
        DataTypes.Order storage bidOrder = bidOrders[_nftAddress][_tokenId][_msgSender()];
        // update buy order
        bidOrder.payToken = _payToken;
        bidOrder.price = _price;
        bidOrder.deadline = _deadline;

        emit Events.BidUpdated(_msgSender(), _nftAddress, _tokenId, _payToken, _price, _deadline);
    }

    /**
     * @notice Accepts a bid order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     * @param _user The owner of bid order.
     */
    function acceptBid(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) external nonReentrant validBid(_nftAddress, _tokenId, _user) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][_user];

        DataTypes.Royalty memory royalty = royalties[bidOrder.nftAddress];
        // pay to msg.sender
        uint256 feeAmount = _payWithFee(
            bidOrder.owner,
            _msgSender(),
            bidOrder.payToken,
            bidOrder.price,
            royalty.receiver,
            royalty.percentage
        );
        // transfer nft
        IERC721(_nftAddress).safeTransferFrom(_msgSender(), _user, _tokenId);

        emit Events.OrdersMatched(
            _msgSender(),
            bidOrder.owner,
            _nftAddress,
            _tokenId,
            bidOrder.payToken,
            bidOrder.price,
            royalty.receiver,
            feeAmount
        );

        delete bidOrders[_nftAddress][_tokenId][_user];
    }

    function _payWithFee(
        address from,
        address to,
        address token,
        uint256 amount,
        address feeReceiver,
        uint256 feePercentage
    ) internal returns (uint256 feeAmount) {
        if (token == Constants.NATIVE_CSB) {
            require(msg.value >= amount, "NotEnoughFunds");

            // pay CSB
            if (feeReceiver != address(0)) {
                feeAmount = (amount / 10000) * feePercentage;
                payable(feeReceiver).transfer(feeAmount);
                payable(to).transfer(amount - feeAmount);
            } else {
                payable(to).transfer(amount);
            }
        } else {
            // refund CSB
            if (msg.value > 0) {
                payable(from).transfer(msg.value);
            }
            // pay ERC20
            if (feeReceiver != address(0)) {
                feeAmount = (amount / 10000) * feePercentage;
                IERC20(token).safeTransferFrom(from, feeReceiver, feeAmount);
                IERC20(token).safeTransferFrom(from, to, amount - feeAmount);
            } else {
                IERC20(token).safeTransferFrom(from, to, amount);
            }
        }
    }

    function _now() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice returns the revision number of the contract.
     **/
    function getRevision() external pure returns (uint256) {
        return REVISION;
    }
}
