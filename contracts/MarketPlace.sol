// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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

    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    modifier askNotExists(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory askOrder = _askOrders[nftAddress][tokenId][user];
        require(askOrder.deadline == 0, "AskExists");
        _;
    }

    modifier askExists(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory askOrder = _askOrders[nftAddress][tokenId][user];
        require(askOrder.deadline > 0, "AskNotExists");
        _;
    }

    modifier validAsk(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory askOrder = _askOrders[nftAddress][tokenId][user];
        // slither-disable-next-line timestamp
        require(askOrder.deadline >= _now(), "AskExpiredOrNotExists");
        _;
    }

    modifier bidNotExists(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory bidOrder = _bidOrders[nftAddress][tokenId][user];
        require(bidOrder.deadline == 0, "BidExists");
        _;
    }

    modifier bidExists(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory bidOrder = _bidOrders[nftAddress][tokenId][user];
        require(bidOrder.deadline > 0, "BidNotExists");
        _;
    }

    modifier validBid(
        address nftAddress,
        uint256 tokenId,
        address user
    ) {
        DataTypes.Order memory bidOrder = _bidOrders[nftAddress][tokenId][user];
        require(bidOrder.deadline != 0, "BidNotExists");
        require(bidOrder.deadline >= _now(), "BidExpired");
        _;
    }

    modifier validPayToken(address payToken) {
        require(payToken == WCSB || payToken == Constants.NATIVE_CSB, "InvalidPayToken");
        _;
    }

    modifier validDeadline(uint256 deadline) {
        require(deadline > _now(), "InvalidDeadline");
        _;
    }

    modifier validPrice(uint256 price) {
        require(price > 0, "InvalidPrice");
        _;
    }

    /**
     * @notice Initializes the MarketPlace, setting the initial web3Entry address and WCSB address.
     * @param web3Entry_ The address of web3Entry.
     * @param wcsb_ The address of WCSB.
     */
    function initialize(address web3Entry_, address wcsb_) external override initializer {
        web3Entry = web3Entry_;
        WCSB = wcsb_;
    }

    function setRoyalty(
        uint256 characterId,
        uint256 noteId,
        address receiver,
        uint256 percentage
    ) external override {
        require(percentage <= Constants.MAX_ROYALTY, "InvalidPercentage");
        // check character owner
        require(msg.sender == IERC721(web3Entry).ownerOf(characterId), "NotCharacterOwner");

        // check mintNFT address
        DataTypes.Note memory note = IWeb3Entry(web3Entry).getNote(characterId, noteId);
        require(note.mintNFT != address(0), "NoMintNFT");

        // set royalty
        _royalties[note.mintNFT].receiver = receiver;
        _royalties[note.mintNFT].percentage = percentage;

        emit Events.RoyaltySet(msg.sender, note.mintNFT, receiver, percentage);
    }

    function ask(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        askNotExists(nftAddress, tokenId, _msgSender())
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        require(IERC165(nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");
        require(IERC721(nftAddress).ownerOf(tokenId) == _msgSender(), "NotERC721TokenOwner");

        // save sell order
        _askOrders[nftAddress][tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            nftAddress,
            tokenId,
            payToken,
            price,
            deadline
        );

        emit Events.AskCreated(_msgSender(), nftAddress, tokenId, WCSB, price, deadline);
    }

    function updateAsk(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        askExists(nftAddress, tokenId, _msgSender())
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        DataTypes.Order storage askOrder = _askOrders[nftAddress][tokenId][_msgSender()];
        // update ask order
        askOrder.payToken = payToken;
        askOrder.price = price;
        askOrder.deadline = deadline;

        emit Events.AskUpdated(_msgSender(), nftAddress, tokenId, payToken, price, deadline);
    }

    function cancelAsk(
        address nftAddress,
        uint256 tokenId
    ) external override askExists(nftAddress, tokenId, _msgSender()) {
        delete _askOrders[nftAddress][tokenId][_msgSender()];

        emit Events.AskCanceled(_msgSender(), nftAddress, tokenId);
    }

    function acceptAsk(
        address nftAddress,
        uint256 tokenId,
        address user
    ) external payable override nonReentrant validAsk(nftAddress, tokenId, user) {
        DataTypes.Order memory askOrder = _askOrders[nftAddress][tokenId][user];

        DataTypes.Royalty memory royalty = _royalties[askOrder.nftAddress];
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
        IERC721(nftAddress).safeTransferFrom(user, _msgSender(), tokenId);

        emit Events.OrdersMatched(
            askOrder.owner,
            _msgSender(),
            nftAddress,
            tokenId,
            askOrder.payToken,
            askOrder.price,
            royalty.receiver,
            feeAmount
        );

        delete _askOrders[nftAddress][tokenId][user];
    }

    function bid(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        bidNotExists(nftAddress, tokenId, _msgSender())
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        require(payToken != Constants.NATIVE_CSB, "NativeCSBNotAllowed");
        require(IERC165(nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");

        // save buy order
        _bidOrders[nftAddress][tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            nftAddress,
            tokenId,
            payToken,
            price,
            deadline
        );

        emit Events.BidCreated(_msgSender(), nftAddress, tokenId, payToken, price, deadline);
    }

    function cancelBid(
        address nftAddress,
        uint256 tokenId
    ) external override bidExists(nftAddress, tokenId, _msgSender()) {
        delete _bidOrders[nftAddress][tokenId][_msgSender()];

        emit Events.BidCanceled(_msgSender(), nftAddress, tokenId);
    }

    function updateBid(
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    )
        external
        override
        validBid(nftAddress, tokenId, _msgSender())
        validPayToken(payToken)
        validDeadline(deadline)
        validPrice(price)
    {
        DataTypes.Order storage bidOrder = _bidOrders[nftAddress][tokenId][_msgSender()];
        // update buy order
        bidOrder.payToken = payToken;
        bidOrder.price = price;
        bidOrder.deadline = deadline;

        emit Events.BidUpdated(_msgSender(), nftAddress, tokenId, payToken, price, deadline);
    }

    function acceptBid(
        address nftAddress,
        uint256 tokenId,
        address user
    ) external override nonReentrant validBid(nftAddress, tokenId, user) {
        DataTypes.Order memory bidOrder = _bidOrders[nftAddress][tokenId][user];

        DataTypes.Royalty memory royalty = _royalties[bidOrder.nftAddress];
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
        IERC721(nftAddress).safeTransferFrom(_msgSender(), user, tokenId);

        emit Events.OrdersMatched(
            _msgSender(),
            bidOrder.owner,
            nftAddress,
            tokenId,
            bidOrder.payToken,
            bidOrder.price,
            royalty.receiver,
            feeAmount
        );

        delete _bidOrders[nftAddress][tokenId][user];
    }

    function getAskOrder(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view override returns (DataTypes.Order memory) {
        return _askOrders[nftAddress][tokenId][owner];
    }

    function getBidOrder(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) external view override returns (DataTypes.Order memory) {
        return _bidOrders[nftAddress][tokenId][owner];
    }

    function getRoyalty(address token) external view override returns (DataTypes.Royalty memory) {
        return _royalties[token];
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
                // slither-disable-next-line arbitrary-send-eth
                payable(to).transfer(amount - feeAmount);
            } else {
                // slither-disable-next-line arbitrary-send-eth
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
        // slither-disable-next-line timestamp
        return block.timestamp;
    }
}
