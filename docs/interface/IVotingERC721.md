# Solidity API

## IVotingERC721

### MintParam

```solidity
struct MintParam {
  address account;
  uint256 votes;
}
```

### AlreadyExistDescriptor

```solidity
error AlreadyExistDescriptor()
```

### AlreadyHasRole

```solidity
error AlreadyHasRole(address addr)
```

### AlreadyHasNoRole

```solidity
error AlreadyHasNoRole(address addr)
```

### PreMintingIsAlreadyDone

```solidity
error PreMintingIsAlreadyDone()
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

