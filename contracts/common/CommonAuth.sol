// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import './ICommonAuth.sol';
import './ICommonError.sol';

contract CommonAuth is ICommonAuth, ICommonError {
    address public override owner;
    address public override executor;

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyOwnerOrExecutor {
        _checkOwnerOrExecutor();
        _;
    }
    
    constructor(address owner_) {
        _setOwner(owner_);
    }

    function setOwner(address owner_) public override onlyOwner {
        _setOwner(owner_);
    }

    function setExecutor(address executor_) external override onlyOwnerOrExecutor {
        _setExecutor(executor_);
    }

    function _setOwner(address owner_) internal {
        if (owner == owner_) {
            revert InvalidAddress(owner_);
        }
        emit OwnerChanged(owner, owner_);
        owner = owner_;
    }

    function _setExecutor(address executor_) internal {
        if (executor == executor_) {
            revert InvalidAddress(executor_);
        }
        emit ExecutorChanged(executor, executor_);
        executor = executor_;
    }
    
    function _checkOwner() internal view {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
    }

    function _checkOwnerOrExecutor() internal view {
        if (msg.sender != owner && msg.sender != executor) {
            revert Unauthorized(msg.sender);
        }
    }
}