// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

interface IBaseTimeLock {
    enum OperationState {
        Unset,
        Waiting,
        Ready,
        Done,
        Cancel
    }

    struct DataParams {
        address target;
        bytes payload;
    }

    struct DataInfo {
        DataParams[] data;
        uint256 scheduledTimestamp;
        OperationState state;
    }

    event Enqueue(bytes32 id, DataParams[] data, uint256 scheduledTimestamp, uint256 salt);
    event Execute(bytes32 id);
    event Cancel(bytes32 id);

    error DoesNotExistData(bytes32 id);
    error AlreadyExistData(bytes32 id);
    error AlreadyExecutedData(bytes32 id);
    error AlreadyCanceledData(bytes32 id);
    error NotYetReady(bytes32 id);
    error InvalidNumber(uint256 input);
    error InvalidData(DataParams data);

    function enqueue(DataParams[] calldata params, uint256 delay) external;
    function execute(bytes32[] calldata ids) external;
    function cancel(bytes32[] calldata ids) external;
    function operationState(bytes32 id) external view returns (OperationState state);
    function dataInfoOf(bytes32 id) external view returns (DataInfo memory dataInfo);
}