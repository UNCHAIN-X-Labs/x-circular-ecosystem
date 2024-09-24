# Solidity API

## IBaseTimeLock

### OperationState

```solidity
enum OperationState {
  Unset,
  Waiting,
  Ready,
  Done,
  Cancel
}
```

### DataParams

```solidity
struct DataParams {
  address target;
  bytes payload;
}
```

### DataInfo

```solidity
struct DataInfo {
  bytes32 data;
  uint256 scheduledTimestamp;
  enum IBaseTimeLock.OperationState state;
}
```

### ExecuteParams

```solidity
struct ExecuteParams {
  struct IBaseTimeLock.DataParams[] dataParams;
  bytes32 id;
}
```

### Enqueue

```solidity
event Enqueue(bytes32 id, struct IBaseTimeLock.DataParams[] data, uint256 scheduledTimestamp, uint256 salt)
```

### Execute

```solidity
event Execute(bytes32 id)
```

### Cancel

```solidity
event Cancel(bytes32 id)
```

### DoesNotExistData

```solidity
error DoesNotExistData(bytes32 id)
```

### AlreadyExistData

```solidity
error AlreadyExistData(bytes32 id)
```

### AlreadyExecutedData

```solidity
error AlreadyExecutedData(bytes32 id)
```

### AlreadyCanceledData

```solidity
error AlreadyCanceledData(bytes32 id)
```

### NotYetReady

```solidity
error NotYetReady(bytes32 id)
```

### InvalidData

```solidity
error InvalidData(struct IBaseTimeLock.DataParams data)
```

### InvalidHashData

```solidity
error InvalidHashData(struct IBaseTimeLock.DataParams[] data, bytes32 id)
```

### enqueue

```solidity
function enqueue(struct IBaseTimeLock.DataParams[] params, uint256 delay) external
```

### execute

```solidity
function execute(struct IBaseTimeLock.ExecuteParams[] params) external
```

### cancel

```solidity
function cancel(bytes32[] ids) external
```

### operationState

```solidity
function operationState(bytes32 id) external view returns (enum IBaseTimeLock.OperationState state)
```

### dataInfoOf

```solidity
function dataInfoOf(bytes32 id) external view returns (struct IBaseTimeLock.DataInfo dataInfo)
```

