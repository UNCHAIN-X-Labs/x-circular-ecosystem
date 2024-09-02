// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {IBaseTimeLock} from "./interface/IBaseTimeLock.sol";
import {CommonAuth} from "./common/CommonAuth.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title TimeLockController
 * @notice The {TimelockController} is based on OpenZeppelin’s TimelockController (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol).
 * The key differences from the original code are as follows:
 * While the original version assigns specific roles for executing different functions, in this version, actions can only be executed by two accounts: the owner and the executor.
 * The reason for this is to facilitate a gradual transfer of authority from the owner to the DAO.
 * At the point when all authority is handed over to the DAO, the owner address will be set to the zero address, thereby relinquishing control.
 * The executor will be set to a contract within the DAO responsible for proposing and executing decisions, rather than being an externally owned account (EOA).
 */
contract TimeLockController is IBaseTimeLock, CommonAuth, ReentrancyGuard {
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);
    uint256 internal constant _CANCEL_TIMESTAMP = uint256(2);
    uint256 private _salt;
    uint256 public immutable minDelay;
    uint256 public immutable maxDelay;

    mapping(bytes32 => bytes32) private _data;
    mapping(bytes32 => uint256) private _scheduledTimestamp;

    constructor(address owner_, uint256 minDelay_, uint256 maxDelay_) CommonAuth(owner_) {
        // The minimum delay waiting time is 48 hours.
        if (minDelay_ < 172800) {
            revert InvalidNumber(minDelay_);
        }
        
        if (minDelay_ > maxDelay_) {
            revert InvalidNumber(maxDelay_);
        }

        minDelay = minDelay_;
        maxDelay = maxDelay_;
    }

    /**
     * Add transaction data to the execution queue.
     * @param params Information on the transaction data to be executed.
     * @param delay Delay before execution.
     */
    function enqueue(DataParams[] calldata params, uint256 delay) external nonReentrant onlyOwnerOrExecutor {
        if(delay < minDelay || delay > maxDelay) {
            revert InvalidNumber(delay);
        }

        for (uint256 i = 0; i < params.length; ++i) {
            if (_validateCodeSize(params[i].target) == 0) {
                revert InvalidAddress(params[i].target);
            }
        }

        bytes32 id = getId(params, ++_salt);

        if(operationState(id) != OperationState.Unset) {
            revert AlreadyExistData(id);
        }

        uint256 scheduledTimestamp = block.timestamp + delay;
        bytes32 paramsHash = keccak256(abi.encode(params));

        _data[id] = paramsHash;
        _scheduledTimestamp[id] = scheduledTimestamp;

        emit Enqueue(id, params, scheduledTimestamp, _salt);
    }

    /**
     * Execute the transaction data in the queue.
     * @param params Array of {ExecuteParams}.
     */
    function execute(ExecuteParams[] calldata params) external nonReentrant onlyOwnerOrExecutor {
        for (uint256 i = 0; i < params.length; ++i) {
            OperationState state = operationState(params[i].id);

            if (state == OperationState.Unset) {
                revert DoesNotExistData(params[i].id);
            }

            if (state == OperationState.Done) {
                revert AlreadyExecutedData(params[i].id);
            }

            if (state == OperationState.Cancel) {
                revert AlreadyCanceledData(params[i].id);
            }

            if (state == OperationState.Waiting) {
                revert NotYetReady(params[i].id);
            }

            _execute(params[i]);
            _scheduledTimestamp[params[i].id] = _DONE_TIMESTAMP;

            emit Execute(params[i].id);
        }
    }

    /**
     * Cancel the transaction data from the queue.
     * @param ids Array of queue IDs to cancel.
     */
    function cancel(bytes32[] calldata ids) external nonReentrant onlyOwnerOrExecutor {
        for (uint256 i = 0; i < ids.length; ++i) {
            OperationState state = operationState(ids[i]);

            if (state == OperationState.Unset) {
                revert DoesNotExistData(ids[i]);
            }

            if (state == OperationState.Done) {
                revert AlreadyExecutedData(ids[i]);
            }

            if (state == OperationState.Cancel) {
                revert AlreadyCanceledData(ids[i]);
            }

            _scheduledTimestamp[ids[i]] = _CANCEL_TIMESTAMP;

            emit Cancel(ids[i]);
        }
    }

    /**
     * Return operation state
     * The order of states is as follows:
     * Unset - Waiting - Ready / Cancel - Done / Cancel
     * @param id Queue ID
     */
    function operationState(bytes32 id) public view returns (OperationState state) {
        uint256 scheduledTimestamp = _scheduledTimestamp[id];

        if (scheduledTimestamp == 0) {
            state = OperationState.Unset;
        } else if (scheduledTimestamp == _DONE_TIMESTAMP) {
            state = OperationState.Done;
        } else if (scheduledTimestamp == _CANCEL_TIMESTAMP) {
            state = OperationState.Cancel;
        } else if (scheduledTimestamp > block.timestamp) {
            state = OperationState.Waiting;
        } else {
            state = OperationState.Ready;
        }
    }

    function dataInfoOf(bytes32 id) public view returns (DataInfo memory dataInfo) {
        dataInfo.data = _data[id];
        dataInfo.scheduledTimestamp = _scheduledTimestamp[id];
        dataInfo.state = operationState(id);
    }

    function getId(DataParams[] calldata params, uint256 salt) public pure returns (bytes32) {
        return keccak256(abi.encode(params, salt));
    }

    function _execute(ExecuteParams calldata params) internal {
        if (_data[params.id] != keccak256(abi.encode(params.dataParams))) {
            revert InvalidHashData(params.dataParams, params.id);
        }

        for (uint256 i = 0; i < params.dataParams.length; ++i) {
            (bool success, bytes memory returndata) = params.dataParams[i].target.call(params.dataParams[i].payload);
            Address.verifyCallResult(success, returndata);
        }
    }

    function _validateCodeSize(address addr) internal view returns (uint32 size) {
        assembly {
            size := extcodesize(addr)
        }
    }
}