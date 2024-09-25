# Solidity API

## XExplosion

{XExplosion} is a contract that burns UNX tokens to generate new tokens.
The new tokens are created in proportion to the amount of UNX burned, according to a specific ratio.

### burningToken

```solidity
contract IERC20Burnable burningToken
```

The token to be burned should be the UNX Token.

### mintingToken

```solidity
contract IERC20Mintable mintingToken
```

The token to be minted.

### multiplier

```solidity
uint256 multiplier
```

A multiple of the quantity of newly minted tokens.

### Explosion

```solidity
event Explosion(address account, uint256 burned, uint256 minted)
```

This event should be emitted when the explode function is executed.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that executed. |
| burned | uint256 | The amount of UNX tokens burned. |
| minted | uint256 | The amount of new tokens minted. |

### constructor

```solidity
constructor(uint256 multiplier_, address burningToken_, string name_, string symbol_) public
```

### explode

```solidity
function explode(uint256 amount) external returns (uint256 mintedAmount)
```

Burn UNX to receive new tokens.
Need to approve the UNX tokens for this contract in advance.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens to be burned​. |

### _validateCodeSize

```solidity
function _validateCodeSize(address addr) internal view returns (uint32 size)
```

