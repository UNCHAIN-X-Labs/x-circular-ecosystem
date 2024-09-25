# Solidity API

## IXRecycling

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
  uint256 earned;
  uint256 totalShare;
  uint256 share;
  uint256 totalClaimedReward;
  uint256 allocatedRewardPerDay;
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

### AddShare

```solidity
event AddShare(address account, uint256 share)
```

### Allocate

```solidity
event Allocate(uint256 oldValue, uint256 newValue)
```

### Claim

```solidity
event Claim(address account, uint256 reward)
```

### RemoveShare

```solidity
event RemoveShare(address account, uint256 share)
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

