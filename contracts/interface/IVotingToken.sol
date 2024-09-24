// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

interface IVotingToken {
    /**
     * @notice Mint voting token
     * @param to The address of receiver.
     * @param votes The number of votes.
     */
    function mint(address to, uint256 votes) external;
}