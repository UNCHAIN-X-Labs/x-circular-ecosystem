// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import "./interface/IBaseTimeLock.sol";
import "./common/CommonAuth.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract TimeLockController is IBaseTimeLock, CommonAuth, ReentrancyGuard {
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);
    uint256 internal constant _CANCEL_TIMESTAMP = uint256(2);
    uint256 private _salt;
    uint256 public immutable minDelay;
    uint256 public immutable maxDelay;

    mapping(bytes32 => DataParams[]) private _data;
    mapping(bytes32 => uint256) private _scheduledTimestamp;

    constructor(address owner_, uint256 minDelay_, uint256 maxDelay_) CommonAuth(owner_) {
        minDelay = minDelay_;
        maxDelay = maxDelay_;
    }

    function enqueue(DataParams[] calldata params, uint256 delay) external nonReentrant onlyOwnerOrExecutor {
        if(delay < minDelay || delay > maxDelay) {
            revert InvalidNumber(delay);
        }

        _validationWithStaticCall(params);

        bytes32 id = getId(params, ++_salt);

        if(operationState(id) != OperationState.Unset) {
            revert AlreadyExistData(id);
        }

        uint256 scheduledTimestamp = block.timestamp + delay;

        _data[id] = params;
        _scheduledTimestamp[id] = scheduledTimestamp;

        emit Enqueue(id, params, scheduledTimestamp, _salt);
    }

    function execute(bytes32[] calldata ids) external nonReentrant onlyOwnerOrExecutor {
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

            if (state == OperationState.Waiting) {
                revert NotYetReady(ids[i]);
            }

            _execute(ids[i]);
            _scheduledTimestamp[ids[i]] = _DONE_TIMESTAMP;

            emit Execute(ids[i]);
        }
    }

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

    function _execute(bytes32 id) internal {
        DataParams[] memory data = _data[id];
        for (uint256 i = 0; i < data.length; ++i) {
            (bool success, bytes memory returndata) = data[i].target.call(data[i].payload);
            Address.verifyCallResult(success, returndata);
        }
    }

    function _validationWithStaticCall(DataParams[] calldata data) internal view {
        for (uint256 i = 0; i < data.length; ++i) {
            (bool success, ) = data[i].target.staticcall(data[i].payload);
            
            if (!success) {
                revert InvalidData(data[i]);
            }
        }
    }
}