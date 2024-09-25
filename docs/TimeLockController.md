# Solidity API

## TimeLockController

The {TimelockController} is based on OpenZeppelin’s TimelockController (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol).
The key differences from the original code are as follows:
While the original version assigns specific roles for executing different functions, in this version, actions can only be executed by two accounts: the owner and the executor.
The reason for this is to facilitate a gradual transfer of authority from the owner to the DAO.
At the point when all authority is handed over to the DAO, the owner address will be set to the zero address, thereby relinquishing control.
The executor will be set to a contract within the DAO responsible for proposing and executing decisions, rather than being an externally owned account (EOA).

### _DONE_TIMESTAMP

```solidity
uint256 _DONE_TIMESTAMP
```

### _CANCEL_TIMESTAMP

```solidity
uint256 _CANCEL_TIMESTAMP
```

### minDelay

```solidity
uint256 minDelay
```

### maxDelay

```solidity
uint256 maxDelay
```

### constructor

```solidity
constructor(address owner_, uint256 minDelay_, uint256 maxDelay_) public
```

### enqueue

```solidity
function enqueue(struct IBaseTimeLock.DataParams[] params, uint256 delay) external
```

Add transaction data to the execution queue.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IBaseTimeLock.DataParams[] | Information on the transaction data to be executed. |
| delay | uint256 | Delay before execution. |

### execute

```solidity
function execute(struct IBaseTimeLock.ExecuteParams[] params) external
```

Execute the transaction data in the queue.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IBaseTimeLock.ExecuteParams[] | Array of {ExecuteParams}. |

### cancel

```solidity
function cancel(bytes32[] ids) external
```

Cancel the transaction data from the queue.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| ids | bytes32[] | Array of queue IDs to cancel. |

### operationState

```solidity
function operationState(bytes32 id) public view returns (enum IBaseTimeLock.OperationState state)
```

Return operation state
The order of states is as follows:
Unset - Waiting - Ready / Cancel - Done / Cancel

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| id | bytes32 | Queue ID |

### dataInfoOf

```solidity
function dataInfoOf(bytes32 id) public view returns (struct IBaseTimeLock.DataInfo dataInfo)
```

### getId

```solidity
function getId(struct IBaseTimeLock.DataParams[] params, uint256 salt) public pure returns (bytes32)
```

### _execute

```solidity
function _execute(struct IBaseTimeLock.ExecuteParams params) internal
```

### _validateCodeSize

```solidity
function _validateCodeSize(address addr) internal view returns (uint32 size)
```

