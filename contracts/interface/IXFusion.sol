// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import '../common/ICommonError.sol';

interface IXFusion is ICommonError {
    struct ShareInfo {
        uint256 share;
        uint256 userRewardPerSharePaid;
        uint256 reward;
    }

    struct DashboardInfo {
        uint256 totalBurnedUNX;
        uint256 totalBurnedXPT;
        uint256 allocatedRewardPerDay;
        uint256 balanceOfUNX;
        uint256 balanceOfXPT;
        uint256 balanceOfVP;
        uint256 totalShare;
        uint256 share;
        uint256 earned;
    }

    struct AllocateVotingPowerParams {
        address account;
        uint256 votingPower;
    }

    event Activate();
    event Fusion(address indexed account, uint256 input, uint256 oldShare, uint256 oldTotalShare, uint256 newShare, uint256 newTotalShare);
    event Allocate(uint256 oldValue, uint256 newValue);
    event Claim(address indexed account, uint256 reward, uint256 oldShare, uint256 oldTotalShare, uint256 newShare, uint256 newTotalShare);
    event UpdateVotes(address indexed account, uint256 oldValue, uint256 newValue);

    error AlreadyInitialized();
    error DoesNotExistInfo(address account);
    error InsufficientReward(uint256 required, uint256 remains);
    error InactiveProtocol();
    error ExceedMinRequired(uint256 required, uint256 expected);
    error InsufficientVotes(address account);

    /**
     * @notice Burn tokens to add share.
     * Additionally, earn voting token based on the amount of tokens burned.
     * @param amount The amount of tokens to burn​
     * @return expectedTotalShare Expected total share
     * @return expectedShare Expected share
     */
    function fuse(uint256 amount) external returns (uint256 expectedTotalShare, uint256 expectedShare);

    /**
     * @notice Claim reward.
     * The share will also be reduced by the same ratio as the claimed reward compared to the total reward.​
     * It will revert if the remaining share is less than the required minimum remaining share.​
     * @param minRequiredRemains Required minimum remaining share
     * @param requiredReward Required reward claim amount
     * @return remainShare The Remaining share
     * @return remainTotalShare The total remaing share
     */
    function claim(uint256 minRequiredRemains, uint256 requiredReward) external returns (uint256 remainShare, uint256 remainTotalShare);

    /**
     * @notice Mint voting token based on the voting power allocated to the account.
     * @param requiredAmount The required amount for mint.
     */
    function mintVotingToken(uint256 requiredAmount) external;

    /**
     * @notice Return dashboard Information.
     * @param account The address of user.
     * @param unx The contract address of UNX Token.
     * @param xPlosion The contract address of XPlosion.
     */
    function dashboardInfo(address account, address unx, address xPlosion) external view returns (DashboardInfo memory result);

    /**
     * @notice Returns the currently earned reward amount.
     * @param account The address of account
     */
    function earned(address account) external view returns (uint256);

    /**
     * @notice Return expected result when execute fuse.
     * @param amount The amount of tokens to burn​
     * @return currentTotalShare Current total share
     * @return currentShare Current share
     * @return expectedTotalShare Expected total share
     * @return expectedShare Expected share
     * @return votingPower Expected voting power
     */
    function expectFusion(uint256 amount) external view returns (
        uint256 currentTotalShare,
        uint256 currentShare,
        uint256 expectedTotalShare,
        uint256 expectedShare,
        uint256 votingPower
    );
}