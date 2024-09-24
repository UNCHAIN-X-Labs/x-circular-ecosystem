// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import '../common/ICommonError.sol';

interface IXRecycling is ICommonError {
    struct ShareInfo {
        uint256 share;
        uint256 userRewardPerSharePaid;
        uint256 reward;
    }

    struct DashboardInfo {
        uint256 earned;
        uint256 totalShare;
        uint256 share;
        uint256 totalClaimedReward;
        uint256 allocatedRewardPerDay;
    }

    struct AllocateVotingPowerParams {
        address account;
        uint256 votingPower;
    }

    event Activate();
    event AddShare(address indexed account, uint256 share);
    event Allocate(uint256 oldValue, uint256 newValue);
    event Claim(address indexed account, uint256 reward);
    event RemoveShare(address indexed account, uint256 share);
    event UpdateVotes(address indexed account, uint256 oldValue, uint256 newValue);

    error AlreadyInitialized();
    error DoesNotExistInfo(address account);
    error InsufficientReward(uint256 required, uint256 remains);
    error InactiveProtocol();
    error ExceedMinRequired(uint256 required, uint256 expected);
    error InsufficientVotes(address account);
}