# Solidity API

## XFusion

{XFusion} is a protocol contract designed to burn tokens to gain share and receive token rewards based on that share.
The share accumulates over time, however when rewards are claimed, the existing share is reduced proportionally to the ratio of the claimed reward to the total remaining rewards.
Additionally, each time add to share, receive voting power that can be used in future governance votes.
This voting power will later be exchanged for voting tokens.

### halvingProtocol

```solidity
contract IHalvingProtocol halvingProtocol
```

UNX Halving Contract

### burningToken

```solidity
contract IERC20Burnable burningToken
```

XPT ERC20 Contract

### votesMultiplier

```solidity
uint256 votesMultiplier
```

Multiplier for calculating vote allocation

### PRECISION

```solidity
uint256 PRECISION
```

Precision for calculating share deduction ratio

### votingToken

```solidity
contract IVotingToken votingToken
```

Voting token Contract

### actived

```solidity
bool actived
```

Active status

### allocation

```solidity
uint256 allocation
```

Allocated reward ratio. Apply 2 decimals. 100.00 % => 10000

### lastUpdatedBlock

```solidity
uint256 lastUpdatedBlock
```

Last updated block number

### rewardPerShareStored

```solidity
uint256 rewardPerShareStored
```

Stored reward per share​

### totalShare

```solidity
uint256 totalShare
```

Total Share

### totalBurnedAmount

```solidity
uint256 totalBurnedAmount
```

Total burned amount of XPT

### claimedReward

```solidity
uint256 claimedReward
```

Total claimed reward amount

### initInputBlock

```solidity
uint256 initInputBlock
```

The block number where the share was first added.

### minRequireForMint

```solidity
uint256 minRequireForMint
```

The minimum amount required to mint voting tokens

### shareInfos

```solidity
mapping(address => struct IXFusion.ShareInfo) shareInfos
```

The share information per account

### votesOf

```solidity
mapping(address => uint256) votesOf
```

Returns the number of voting rights allocated to each account.

### updateReward

```solidity
modifier updateReward()
```

### constructor

```solidity
constructor(address halvingProtocol_, address burningToken_, uint256 votesMultiplier_) public
```

### initialize

```solidity
function initialize(uint256 allocation_) external
```

Set the reward allocation and active status to active.​
It should be executed only once for the first time by owner or executor.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| allocation_ | uint256 | UNX reward allocation |

### initializeMintingConfig

```solidity
function initializeMintingConfig(address votingToken_, uint256 minRequireForMint_) external
```

Initialize voting token minting coniguration.
Only once execute by owner.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| votingToken_ | address | The voting token contract |
| minRequireForMint_ | uint256 |  |

### preAllocateVotingPower

```solidity
function preAllocateVotingPower(struct IXFusion.AllocateVotingPowerParams[] params) external
```

Allocate pre-voting power as a referral reward for the launchpad.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IXFusion.AllocateVotingPowerParams[] | Array of {AllocateVotingPowerParams} |

### setAllocation

```solidity
function setAllocation(uint256 allocation_) external
```

Set the reward allocation
It should be executed by owner or executor

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| allocation_ | uint256 | UNX reward allocation |

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
function dashboardInfo(address account, address unx, address xPlosion) public view returns (struct IXFusion.DashboardInfo result)
```

Return dashboard Information.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address of user. |
| unx | address | The contract address of UNX Token. |
| xPlosion | address | The contract address of XPlosion. |

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

### earned

```solidity
function earned(address account) public view returns (uint256)
```

Returns the currently earned reward amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| account | address | The address of account |

### lastBlockRewardApplicable

```solidity
function lastBlockRewardApplicable() public view returns (uint256)
```

Returns the last reward block.​

### rewardPerShare

```solidity
function rewardPerShare() public view returns (uint256 reward)
```

Returns the reward amount per share.

### rewardPerBlock

```solidity
function rewardPerBlock() public view returns (uint256 reward)
```

Returns the current reward amount per block.

### rewardPerBlockOf

```solidity
function rewardPerBlockOf(uint256 halvingNum) public view returns (uint256 reward)
```

Returns the reward amount per block for a specific halving number.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| halvingNum | uint256 | The halving number. |

### totalRemainReward

```solidity
function totalRemainReward() public view returns (uint256 remains)
```

Returns the current total remaining reward amount.

### _updateVotes

```solidity
function _updateVotes(address caller, uint256 oldVotes, uint256 newVotes) internal
```

### _updateReward

```solidity
function _updateReward(address account) internal
```

### _setAllocation

```solidity
function _setAllocation(uint256 allocation_) internal
```

### _validateCodeSize

```solidity
function _validateCodeSize(address addr) internal view returns (uint32 size)
```

