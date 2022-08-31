# MarketPlace









## Methods


### acceptAsk

```solidity
function acceptAsk(address nftAddress, uint256 tokenId, address user) external payable
```

Accepts an ask order.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT. |
| user | address | The owner of ask order, as well as the  owner of the NFT. |

### acceptBid

```solidity
function acceptBid(address nftAddress, uint256 tokenId, address user) external nonpayable
```

Accepts a bid order.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT. |
| user | address | The owner of bid order. |

### ask

```solidity
function ask(address nftAddress, uint256 tokenId, address payToken, uint256 price, uint256 deadline) external nonpayable
```

Creates an ask order for an NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT to be sold. |
| payToken | address | The ERC20 token address for buyers to pay. |
| price | uint256 | The sale price for the NFT. |
| deadline | uint256 | The expiration timestamp of the ask order. |

### bid

```solidity
function bid(address nftAddress, uint256 tokenId, address _payToken, uint256 _price, uint256 _deadline) external nonpayable
```

Creates a bid order for an NFT.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT to bid. |
| _payToken | address | The ERC20 token address for buyers to pay. |
| _price | uint256 | The bid price for the NFT. |
| _deadline | uint256 | The expiration timestamp of the bid order. |

### cancelAsk

```solidity
function cancelAsk(address nftAddress, uint256 tokenId) external nonpayable
```

Cancels an ask order.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT. |

### cancelBid

```solidity
function cancelBid(address nftAddress, uint256 tokenId) external nonpayable
```

Cancels a bid order.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT. |

### getAskOrder

```solidity
function getAskOrder(address nftAddress, uint256 tokenId, address owner) external nonpayable returns (struct DataTypes.Order)
```

Gets an ask order.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT to be sold. |
| owner | address | The owner who creates the order. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | DataTypes.Order | undefined |

### getBidOrder

```solidity
function getBidOrder(address nftAddress, uint256 tokenId, address owner) external nonpayable returns (struct DataTypes.Order)
```

Gets a bid order.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT to bid. |
| owner | address | The owner who creates the order. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | DataTypes.Order | undefined |

### getRevision

```solidity
function getRevision() external pure returns (uint256)
```

returns the revision number of the contract.*




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getRoyalty

```solidity
function getRoyalty(address token) external view returns (struct DataTypes.Royalty)
```

Returns the royalty according to a given nft token address.



#### Parameters

| Name | Type | Description |
|---|---|---|
| token | address | The nft token address to query with. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | DataTypes.Royalty | Royalty The royalty struct. |

### initialize

```solidity
function initialize(address _web3Entry, address _wcsb) external nonpayable
```

Initializes the MarketPlace, setting the initial web3Entry address and WCSB address.



#### Parameters

| Name | Type | Description |
|---|---|---|
| _web3Entry | address | The address of web3Entry. |
| _wcsb | address | The address of WCSB. |

### setRoyalty

```solidity
function setRoyalty(uint256 characterId, uint256 noteId, address receiver, uint256 percentage) external nonpayable
```

Sets the royalty.



#### Parameters

| Name | Type | Description |
|---|---|---|
| characterId | uint256 | The character ID of note. |
| noteId | uint256 | The note ID of note. |
| receiver | address | The address receiving the royalty. |
| percentage | uint256 | The percentage of the royalty. (multiply by 100, which means 10000 is 100 percent) |

### updateAsk

```solidity
function updateAsk(address nftAddress, uint256 tokenId, address payToken, uint256 price, uint256 deadline) external nonpayable
```

Updates an ask order.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT. |
| payToken | address | undefined |
| price | uint256 | The new sale price for the NFT. |
| deadline | uint256 | The new expiration timestamp of the ask order. |

### updateBid

```solidity
function updateBid(address nftAddress, uint256 tokenId, address _payToken, uint256 _price, uint256 _deadline) external nonpayable
```

Updates a bid order.



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | The contract address of the NFT. |
| tokenId | uint256 | The token id of the NFT. |
| _payToken | address | The ERC20 token address for buyers to pay. |
| _price | uint256 | The new bid price for the NFT. |
| _deadline | uint256 | The new expiration timestamp of the ask order. |

### web3Entry

```solidity
function web3Entry() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |



