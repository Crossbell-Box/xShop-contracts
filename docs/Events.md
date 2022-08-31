# Events










## Events

### AskCanceled

```solidity
event AskCanceled(address indexed owner, address indexed nftAddress, uint256 indexed tokenId)
```

Emitted when an ask order is canceled.



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | The owner of the ask order. |
| nftAddress `indexed` | address | The contract address of the NFT. |
| tokenId `indexed` | uint256 | The token id of the NFT. |

### AskCreated

```solidity
event AskCreated(address indexed owner, address indexed nftAddress, uint256 indexed tokenId, address payToken, uint256 price, uint256 deadline)
```

Emitted when an ask order is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | The owner of the ask order. |
| nftAddress `indexed` | address | The contract address of the NFT. |
| tokenId `indexed` | uint256 | The token id of the NFT to be sold. |
| payToken  | address | The ERC20 token address for buyers to pay. |
| price  | uint256 | The sale price for the NFT. |
| deadline  | uint256 | The expiration timestamp of the ask order. |

### AskUpdated

```solidity
event AskUpdated(address indexed owner, address indexed nftAddress, uint256 indexed tokenId, address payToken, uint256 price, uint256 deadline)
```

Emitted when an ask order is updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | The owner of the ask order. |
| nftAddress `indexed` | address | The contract address of the NFT. |
| tokenId `indexed` | uint256 | The token id of the NFT. |
| payToken  | address | The ERC20 token address for buyers to pay. |
| price  | uint256 | The new sale price for the NFT. |
| deadline  | uint256 | The expiration timestamp of the ask order. |

### BidCanceled

```solidity
event BidCanceled(address indexed owner, address indexed nftAddress, uint256 indexed tokenId)
```

Emitted when a bid  order is canceled.



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | The owner of the bid order. |
| nftAddress `indexed` | address | The contract address of the NFT. |
| tokenId `indexed` | uint256 | The token id of the NFT. |

### BidCreated

```solidity
event BidCreated(address indexed owner, address indexed nftAddress, uint256 indexed tokenId, address payToken, uint256 price, uint256 deadline)
```

Emitted when a bid order is created.



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | The owner of the bid order. |
| nftAddress `indexed` | address | The contract address of the NFT. |
| tokenId `indexed` | uint256 | The token id of the NFT to bid. |
| payToken  | address | The ERC20 token address for buyers to pay. |
| price  | uint256 | The bid price for the NFT. |
| deadline  | uint256 | The expiration timestamp of the bid order. |

### BidUpdated

```solidity
event BidUpdated(address indexed owner, address indexed nftAddress, uint256 indexed tokenId, address payToken, uint256 price, uint256 deadline)
```

Emitted when a bid order is updated.



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | The owner of the bid order. |
| nftAddress `indexed` | address | The contract address of the NFT. |
| tokenId `indexed` | uint256 | The token id of the NFT. |
| payToken  | address | The ERC20 token address for buyers to pay. |
| price  | uint256 | The new bid price for the NFT. |
| deadline  | uint256 | The expiration timestamp of the bid order. |

### OrdersMatched

```solidity
event OrdersMatched(address indexed seller, address indexed buyer, address indexed nftAddress, uint256 tokenId, address payToken, uint256 price, address royaltyReceiver, uint256 feeAmount)
```

Emitted when a bid/ask order is accepted(matched).



#### Parameters

| Name | Type | Description |
|---|---|---|
| seller `indexed` | address | The seller, as well as the owner of nft. |
| buyer `indexed` | address | The buyer who wanted to paying ERC20 tokens for the nft. |
| nftAddress `indexed` | address | The contract address of the NFT. |
| tokenId  | uint256 | The token id of the NFT. |
| payToken  | address | The ERC20 token address for buyers to pay. |
| price  | uint256 | The price the buyer will pay to the seller. |
| royaltyReceiver  | address | The receiver of the royalty fee. |
| feeAmount  | uint256 | The amount of the royalty fee. |

### RoyaltySet

```solidity
event RoyaltySet(address indexed owner, address indexed nftAddress, address receiver, uint256 percentage)
```

Emitted when the royalty is set by the mintNFT owner.



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner `indexed` | address | The owner of mintNFT. |
| nftAddress `indexed` | address | The mintNFT address. |
| receiver  | address | The percentage of the royalty. |
| percentage  | uint256 | undefined |



