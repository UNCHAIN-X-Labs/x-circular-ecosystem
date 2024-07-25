// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

interface IXRecycling {
    struct ShareInfo {
        uint256 share;
        uint256 userRewardPerSharePaid;
        uint256 reward;
    }

    event Activate();
    event AddShare(address indexed account, uint256 share);
    event Allocate(uint256 oldValue, uint256 newValue);
    event Claim(address indexed account, uint256 reward);
    event RemoveShare(address indexed account, uint256 share);

    error AlreadyInitialized();
    error DoesNotExistInfo(address account);
    error DoesNotExistReward(address account);
    error InactiveProtocol();
    error InvalidAddress(address input);
    error InvalidNumber(uint256 num);
}