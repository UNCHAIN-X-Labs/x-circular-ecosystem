# Solidity API

## XPlosion

{XPlosion} is a contract that burns UNX tokens to generate new tokens.
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

### requiredBurningAmount

```solidity
uint256 requiredBurningAmount
```

Minimum UNX burning requirement for the referral address to be valid.

### totalBurnedAmount

```solidity
uint256 totalBurnedAmount
```

Return total burned amount of UNX.

### burningAmountOf

```solidity
mapping(address => uint256) burningAmountOf
```

Cumulative UNX burning amount by Account.

### referralRewards

```solidity
mapping(address => uint256) referralRewards
```

Cumulative Referral Rewards by Account.

### constructor

```solidity
constructor(uint256 multiplier_, address burningToken_, string name_, string symbol_, uint256 requiredBurningAmount_) public
```

### explode

```solidity
function explode(address inviter, uint256 amount) external returns (uint256 mintedAmount)
```

Burn UNX to receive new tokens.
Need to approve the UNX tokens for this contract in advance.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| inviter | address | The inviter wallet address. |
| amount | uint256 | The amount of tokens to be burned​. |

### setRequiredBurningAmount

```solidity
function setRequiredBurningAmount(uint256 requiredBurningAmount_) external
```

Set requiredBurningAmount.
Only execute by owner or executor.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| requiredBurningAmount_ | uint256 | Minimum UNX burning requirement for the referral address to be valid. |

### validateInviter

```solidity
function validateInviter(address invitee, address inviter) public view returns (bool result)
```

Validate inviter.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| invitee | address | The invitee wallet address. |
| inviter | address | The inviter wallet address. |

### _validateCodeSize

```solidity
function _validateCodeSize(address addr) internal view returns (uint32 size)
```

