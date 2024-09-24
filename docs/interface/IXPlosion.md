# Solidity API

## IXPlosion

### Explosion

```solidity
event Explosion(address account, uint256 burned, uint256 minted)
```

This event should be emitted when the explode function is executed.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The account that executed. |
| burned | uint256 | The amount of UNX token burned. |
| minted | uint256 | The amount of new token minted. |

### Referral

```solidity
event Referral(address inviter, address invitee, uint256 amount, uint256 reward)
```

This event should be emitted when the explode function is executed with a referral.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| inviter | address | The account that inviter |
| invitee | address | The account that invitee. |
| amount | uint256 | The amount of UNX tokens burned by invitee. |
| reward | uint256 | The amount of new token reward to inviter. |

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

### totalBurnedAmount

```solidity
function totalBurnedAmount() external view returns (uint256)
```

Return total burned amount of UNX.

### validateInviter

```solidity
function validateInviter(address invitee, address inviter) external view returns (bool result)
```

Validate inviter.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| invitee | address | The invitee wallet address. |
| inviter | address | The inviter wallet address. |

### requiredBurningAmount

```solidity
function requiredBurningAmount() external view returns (uint256)
```

Minimum UNX burning requirement for the referral address to be valid.

### burningAmountOf

```solidity
function burningAmountOf(address account) external view returns (uint256)
```

Cumulative UNX burning amount by Account.

### referralRewards

```solidity
function referralRewards(address account) external view returns (uint256)
```

Cumulative Referral Rewards by Account.

