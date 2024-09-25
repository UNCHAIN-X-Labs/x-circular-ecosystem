# Solidity API

## VotingERC721

{VotingERC721} is the agenda voting rights NFT to be used in Unchain X governance.
The pre-minted NFT, which is minted only once, is a launchpad referral reward.
After that, new NFTs will only be created within the burn protocol.​

### descriptor

```solidity
address descriptor
```

The address of the token descriptor contract, which handles generating token URIs for voting tokens

### latestId

```solidity
uint256 latestId
```

The ID of the latest token that minted. It will be skips 0.

### commonUri

```solidity
string commonUri
```

The common token URI before reveal.

### minters

```solidity
mapping(address => bool) minters
```

The Addresses with minting authority.
This authority will be granted only to the XRecycling contract and the contract that separates/combines votes.

### votesOf

```solidity
mapping(uint256 => uint256) votesOf
```

Returns the number of voting rights allocated to each token.

### constructor

```solidity
constructor(string name_, string symbol_, string uri_, address minter_) public
```

### mint

```solidity
function mint(address to, uint256 votes) external
```

Mint voting NFT

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address of receiver. |
| votes | uint256 | The number of votes. |

### preMint

```solidity
function preMint(struct IVotingERC721.MintParam[] params) external
```

Pre-minting for launchpad referral rewards.
It should be executed only once for the first time by owner.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IVotingERC721.MintParam[] | The information about the wallet address to receive the NFT and the number of voting rights to be allocated to the token. |

### setMinter

```solidity
function setMinter(address ca, bool trueOrFalse) external
```

Grant the minter authority.
It should be executed only once for the first time by owner.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ca | address | The target contract address |
| trueOrFalse | bool | Whether to grant the authority. |

### setDescriptor

```solidity
function setDescriptor(address descriptor_) external
```

Set the descriptor contract address.
It should be executed only once for the first time by owner.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| descriptor_ | address | The contract address to describe the tokenURI. |

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view returns (string)
```

Returns the tokenURI.
If the descriptor is the zero address, it shows a common URI in an unrevealed state.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The token's ID |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

### _update

```solidity
function _update(address to, uint256 tokenId, address auth) internal virtual returns (address)
```

### _getVotingUnits

```solidity
function _getVotingUnits(address account) internal view virtual returns (uint256)
```

### _increaseBalance

```solidity
function _increaseBalance(address account, uint128 amount) internal virtual
```

### _mintAndAllocateVotes

```solidity
function _mintAndAllocateVotes(address to, uint256 votes) internal
```

### _validateCodeSize

```solidity
function _validateCodeSize(address addr) internal view returns (uint32 size)
```

