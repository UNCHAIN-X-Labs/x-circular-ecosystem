// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import '../common/ICommonError.sol';

interface IXPlosion is ICommonError {
    /**
     * @notice This event should be emitted when the explode function is executed.
     * @param account The account that executed.
     * @param burned The amount of UNX token burned.
     * @param minted The amount of new token minted.
     */
    event Explosion(address indexed account, uint256 burned, uint256 minted);

    /**
     * @notice This event should be emitted when the explode function is executed with a referral.
     * @param inviter The account that inviter
     * @param invitee The account that invitee.
     * @param amount The amount of UNX tokens burned by invitee.
     * @param reward The amount of new token reward to inviter.
     */
    event Referral(address indexed inviter, address invitee, uint256 amount, uint256 reward);

    /**
     * @notice Burn UNX to receive new tokens.
     * Need to approve the UNX tokens for this contract in advance.
     * @param inviter The inviter wallet address.
     * @param amount The amount of tokens to be burned​.
     */
    function explode(address inviter, uint256 amount) external returns (uint256 mintedAmount);

    /**
     * @notice Set requiredBurningAmount.
     * Only execute by owner or executor.
     * @param requiredBurningAmount_ Minimum UNX burning requirement for the referral address to be valid.
     */
    function setRequiredBurningAmount(uint256 requiredBurningAmount_) external;

    /// @notice Return total burned amount of UNX.
    function totalBurnedAmount() external view returns (uint256);

    /**
     * @notice Validate inviter.
     * @param invitee The invitee wallet address.
     * @param inviter The inviter wallet address.
     */
    function validateInviter(address invitee, address inviter) external view returns (bool result);

    /// @notice Minimum UNX burning requirement for the referral address to be valid.
    function requiredBurningAmount() external view returns (uint256);

    /// @notice Cumulative UNX burning amount by Account.
    function burningAmountOf(address account) external view returns (uint256);

    /// @notice Cumulative Referral Rewards by Account.
    function referralRewards(address account) external view returns (uint256);
}