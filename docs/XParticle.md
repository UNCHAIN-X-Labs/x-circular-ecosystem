# Solidity API

## XParticle

{XParticle} is minted at a fixed rate when UNX is burned within the Unchain X ecosystem.

### minter

```solidity
address minter
```

_The minter should be a contract implementing the UNX burning process._

### constructor

```solidity
constructor(string name_, string symbol_, address minter_) public
```

### mint

```solidity
function mint(address to, uint256 amount) external
```

Mint a token.

_Only execute by minter._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The receiver. |
| amount | uint256 | The amount to be minted. |

