# Solidity API

## CommonAuth

### owner

```solidity
address owner
```

### executor

```solidity
address executor
```

### onlyOwner

```solidity
modifier onlyOwner()
```

### onlyOwnerOrExecutor

```solidity
modifier onlyOwnerOrExecutor()
```

### constructor

```solidity
constructor(address owner_) public
```

### setOwner

```solidity
function setOwner(address owner_) public
```

### setExecutor

```solidity
function setExecutor(address executor_) external
```

### _setOwner

```solidity
function _setOwner(address owner_) internal
```

### _setExecutor

```solidity
function _setExecutor(address executor_) internal
```

### _checkOwner

```solidity
function _checkOwner() internal view
```

### _checkOwnerOrExecutor

```solidity
function _checkOwnerOrExecutor() internal view
```

