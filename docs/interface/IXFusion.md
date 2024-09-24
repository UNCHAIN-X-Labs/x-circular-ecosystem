# Solidity API

## IXFusion

### ShareInfo

```solidity
struct ShareInfo {
  uint256 share;
  uint256 userRewardPerSharePaid;
  uint256 reward;
}
```

### DashboardInfo

```solidity
struct DashboardInfo {
  uint256 totalBurnedUNX;
  uint256 totalBurnedXPT;
  uint256 allocatedRewardPerDay;
  uint256 balanceOfUNX;
  uint256 balanceOfXPT;
  uint256 balanceOfVP;
  uint256 totalShare;
  uint256 share;
  uint256 earned;
}
```

### AllocateVotingPowerParams

```solidity
struct AllocateVotingPowerParams {
  address account;
  uint256 votingPower;
}
```

### Activate

```solidity
event Activate()
```

### Fusion

```solidity
event Fusion(address account, uint256 input, uint256 oldShare, uint256 oldTotalShare, uint256 newShare, uint256 newTotalShare)
```

### Allocate

```solidity
event Allocate(uint256 oldValue, uint256 newValue)
```

### Claim

```solidity
event Claim(address account, uint256 reward, uint256 oldShare, uint256 oldTotalShare, uint256 newShare, uint256 newTotalShare)
```

### UpdateVotes

```solidity
event UpdateVotes(address account, uint256 oldValue, uint256 newValue)
```

### AlreadyInitialized

```solidity
error AlreadyInitialized()
```

### DoesNotExistInfo

```solidity
error DoesNotExistInfo(address account)
```

### InsufficientReward

```solidity
error InsufficientReward(uint256 required, uint256 remains)
```

### InactiveProtocol

```solidity
error InactiveProtocol()
```

### ExceedMinRequired

```solidity
error ExceedMinRequired(uint256 required, uint256 expected)
```

### InsufficientVotes

```solidity
error InsufficientVotes(address account)
```

### fuse

```solidity
function fuse(uint256 amount) external returns (uint256 expectedTotalShare, uint256 expectedShare)
```

Burn tokens to add share.
Additionally, earn voting token based on the amount of tokens burned.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens to burn​ |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| expectedTotalShare | uint256 | Expected total share |
| expectedShare | uint256 | Expected share |

### claim

```solidity
function claim(uint256 minRequiredRemains, uint256 requiredReward) external returns (uint256 remainShare, uint256 remainTotalShare)
```

Claim reward.
The share will also be reduced by the same ratio as the claimed reward compared to the total reward.​
It will revert if the remaining share is less than the required minimum remaining share.​

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| minRequiredRemains | uint256 | Required minimum remaining share |
| requiredReward | uint256 | Required reward claim amount |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| remainShare | uint256 | The Remaining share |
| remainTotalShare | uint256 | The total remaing share |

### mintVotingToken

```solidity
function mintVotingToken(uint256 requiredAmount) external
```

Mint voting token based on the voting power allocated to the account.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| requiredAmount | uint256 | The required amount for mint. |

### dashboardInfo

```solidity
function dashboardInfo(address account, address unx, address xPlosion) external view returns (struct IXFusion.DashboardInfo result)
```

Return dashboard Information.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address of user. |
| unx | address | The contract address of UNX Token. |
| xPlosion | address | The contract address of XPlosion. |

### earned

```solidity
function earned(address account) external view returns (uint256)
```

Returns the currently earned reward amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address of account |

### expectFusion

```solidity
function expectFusion(uint256 amount) external view returns (uint256 currentTotalShare, uint256 currentShare, uint256 expectedTotalShare, uint256 expectedShare, uint256 votingPower)
```

Return expected result when execute fuse.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens to burn​ |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| currentTotalShare | uint256 | Current total share |
| currentShare | uint256 | Current share |
| expectedTotalShare | uint256 | Expected total share |
| expectedShare | uint256 | Expected share |
| votingPower | uint256 | Expected voting power |

