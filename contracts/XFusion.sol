// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IXFusion} from './interface/IXFusion.sol';
import {IXPlosion} from './interface/IXPlosion.sol';
import {IHalvingProtocol} from './interface/IHalvingProtocol.sol';
import {IERC20Burnable} from './interface/IERC20Burnable.sol';
import {IVotingToken} from './interface/IVotingToken.sol';
import {CommonAuth} from './common/CommonAuth.sol';

/**
 * @title XFusion
 * @notice {XFusion} is a protocol contract designed to burn tokens to gain share and receive token rewards based on that share.
 * The share accumulates over time, however when rewards are claimed, the existing share is reduced proportionally to the ratio of the claimed reward to the total remaining rewards.
 * Additionally, each time add to share, receive voting power that can be used in future governance votes.
 * This voting power will later be exchanged for voting tokens.
 */
contract XFusion is IXFusion, CommonAuth, ReentrancyGuard {
    /// @notice UNX Halving Contract
    IHalvingProtocol public immutable halvingProtocol;
    /// @notice XPT ERC20 Contract
    IERC20Burnable public immutable burningToken;
    /// @notice Multiplier for calculating vote allocation
    uint256 public immutable votesMultiplier;
    /// @notice Precision for calculating share deduction ratio
    uint256 public constant PRECISION = 1e18;

    /// @notice Voting token Contract
    IVotingToken public votingToken;
    /// @notice Pre-Voting Power Allocation status
    bool private preVotingPowerAllocation;
    /// @notice Active status
    bool public actived;
    /// @notice Allocated reward ratio. Apply 2 decimals. 100.00 % => 10000
    uint256 public allocation;
    /// @notice Last updated block number
    uint256 public lastUpdatedBlock;
    /// @notice Stored reward per share​
    uint256 public rewardPerShareStored;
    /// @notice Total Share
    uint256 public totalShare;
    /// @notice Total burned amount of XPT
    uint256 public totalBurnedAmount;
    /// @notice Total claimed reward amount
    uint256 public claimedReward;
    /// @notice The block number where the share was first added.
    uint256 public initInputBlock;
    /// @notice The minimum amount required to mint voting tokens
    uint256 public minRequireForMint;

    /// @notice The share information per account
    mapping(address => ShareInfo) public shareInfos;

    /// @notice Returns the number of voting rights allocated to each account.
    mapping(address => uint256) public votesOf;

    modifier updateReward() {
        _updateReward(msg.sender);
        _;
    }

    constructor(
        address halvingProtocol_,
        address burningToken_,
        uint256 votesMultiplier_
    ) CommonAuth(msg.sender) {
        if (_validateCodeSize(halvingProtocol_) == 0) {
            revert InvalidAddress(halvingProtocol_);
        }

        if (_validateCodeSize(burningToken_) == 0) {
            revert InvalidAddress(burningToken_);
        }

        if (votesMultiplier_ == 0) {
            revert InvalidNumber(votesMultiplier_);
        }

        halvingProtocol = IHalvingProtocol(halvingProtocol_);
        burningToken = IERC20Burnable(burningToken_);
        votesMultiplier = votesMultiplier_;
    }

    /**
     * @notice Set the reward allocation and active status to active.​
     * It should be executed only once for the first time by owner or executor.
     * @param allocation_ UNX reward allocation
     */
    function initialize(uint256 allocation_) external onlyOwnerOrExecutor {
        if (actived) {
            revert AlreadyInitialized();
        }
        _setAllocation(allocation_);
        actived = true;
        lastUpdatedBlock = block.number;
        emit Activate();
    }

    /**
     * @notice Initialize voting token minting coniguration.
     * Only once execute by owner.
     * @param votingToken_ The voting token contract
     */
    function initializeMintingConfig(
        address votingToken_,
        uint256 minRequireForMint_
    ) external onlyOwnerOrExecutor {
        if (address(votingToken) != address(0)) {
            revert AlreadyInitialized();
        }

        if (_validateCodeSize(votingToken_) == 0) {
            revert InvalidAddress(votingToken_);
        }

        if (minRequireForMint_ == 0) {
            revert InvalidNumber(minRequireForMint_);
        }

        votingToken = IVotingToken(votingToken_);
        minRequireForMint = minRequireForMint_;
    }

    /**
     * @notice Allocate pre-voting power as a referral reward for the launchpad.
     * @param params Array of {AllocateVotingPowerParams}
     */
    function preAllocateVotingPower(
        AllocateVotingPowerParams[] calldata params
    ) external onlyOwnerOrExecutor {
        if (preVotingPowerAllocation || actived) {
            revert AlreadyInitialized();
        }

        for (uint256 i = 0; i < params.length; ++i) {
            _updateVotes(params[i].account, 0, params[i].votingPower);
        }

        preVotingPowerAllocation = true;
    }

    /**
     * @notice Set the reward allocation
     * It should be executed by owner or executor
     * @param allocation_ UNX reward allocation
     */
    function setAllocation(uint256 allocation_) external onlyOwnerOrExecutor {
        _setAllocation(allocation_);
    }

    /// @inheritdoc IXFusion
    function fuse(uint256 amount)
        external
        nonReentrant
        updateReward
        returns (uint256 expectedTotalShare, uint256 expectedShare)
    {
        if (!actived || block.number < halvingProtocol.genesisBlock()) {
            revert InactiveProtocol();
        }

        if (amount == 0) {
            revert InvalidNumber(amount);
        }

        if (initInputBlock == 0) {
            initInputBlock = block.number;
        }

        address caller = msg.sender;
        uint256 oldShare = shareInfos[caller].share;
        uint256 oldTotalShare = totalShare;

        burningToken.burnFrom(caller, amount);

        shareInfos[caller].share += amount;
        totalShare += amount;
        totalBurnedAmount += amount;

        expectedShare = shareInfos[caller].share;
        expectedTotalShare = totalShare;

        emit Fusion(caller, amount, oldShare, oldTotalShare, expectedShare, expectedTotalShare);

        if (amount >= 1e18) {
            uint256 votes = (amount / 1e18) * votesMultiplier;
            uint256 oldVotes = votesOf[caller];
            uint256 newVotes = oldVotes + votes;
            _updateVotes(caller, oldVotes, newVotes);
        }
    }

    /// @inheritdoc IXFusion
    function claim(
        uint256 minRequiredRemains,
        uint256 requiredReward
    )
        external
        nonReentrant
        updateReward
        returns (uint256 remainShare, uint256 remainTotalShare)
    {
        address caller = msg.sender;
        ShareInfo memory shareInfo = shareInfos[caller];
        uint256 currentShare = shareInfo.share;
        uint256 currentTotalShare = totalShare;
        uint256 remainsReward = shareInfo.reward;

        if (currentShare == 0) {
            revert DoesNotExistInfo(caller);
        }

        if (requiredReward > remainsReward) {
            revert InsufficientReward(requiredReward, remainsReward);
        }

        // Calculate reduction ratio
        uint256 quotient = (totalRemainReward() * PRECISION) / requiredReward;
        uint256 subShare = (currentShare * PRECISION) / quotient;
        remainTotalShare = currentTotalShare - subShare;
        remainShare = currentShare - subShare;

        if (remainShare < minRequiredRemains) {
            revert ExceedMinRequired(minRequiredRemains, remainShare);
        }

        // Transfer reward
        halvingProtocol.transferReward(caller, requiredReward);
        shareInfos[caller].reward -= requiredReward;
        claimedReward += requiredReward;

        // Reduce share
        shareInfos[caller].share = remainShare;
        totalShare = remainTotalShare;

        emit Claim(caller, requiredReward, currentShare, currentTotalShare, remainShare, remainTotalShare);
    }

    /// @inheritdoc IXFusion
    function mintVotingToken(uint256 requiredAmount) external nonReentrant {
        if (address(votingToken) == address(0)) {
            revert InvalidAddress(address(votingToken));
        }

        if (requiredAmount < minRequireForMint) {
            revert InvalidNumber(requiredAmount);
        }

        address caller = msg.sender;
        uint256 votes = votesOf[caller];

        if (votes < requiredAmount) {
            revert InsufficientVotes(caller);
        }

        votingToken.mint(caller, requiredAmount);
        _updateVotes(caller, votes, votes - requiredAmount);
    }

    /// @inheritdoc IXFusion
    function dashboardInfo(
        address account,
        address unx,
        address xPlosion
    ) public view returns (DashboardInfo memory result) {
        result.totalBurnedUNX = IXPlosion(xPlosion).totalBurnedAmount();
        result.totalBurnedXPT = totalBurnedAmount;
        result.allocatedRewardPerDay = rewardPerBlock() * 28800;
        result.balanceOfUNX = IERC20Burnable(unx).balanceOf(account);
        result.balanceOfXPT = burningToken.balanceOf(account);
        result.balanceOfVP = votesOf[account];
        result.totalShare = totalShare;
        result.share = shareInfos[account].share;
        result.earned = earned(account);
    }

    /// @inheritdoc IXFusion
    function expectFusion(uint256 amount) external view returns (
        uint256 currentTotalShare,
        uint256 currentShare,
        uint256 expectedTotalShare,
        uint256 expectedShare,
        uint256 votingPower
    ) {
        address caller = msg.sender;
        currentShare = shareInfos[caller].share;
        currentTotalShare = totalShare;
        expectedShare = currentShare + amount;
        expectedTotalShare = currentTotalShare + amount;
        votingPower = amount > 1e18 ? amount / 1e18 : 0;
    }

    /// @inheritdoc IXFusion
    function earned(address account) public view returns (uint256) {
        ShareInfo memory shareInfo = shareInfos[account];
        return
            (shareInfo.share *
                (rewardPerShare() - shareInfo.userRewardPerSharePaid)) /
            1e18 +
            shareInfo.reward;
    }

    /**
     * @notice Returns the last reward block.​
     */
    function lastBlockRewardApplicable() public view returns (uint256) {
        uint256 endBlock = halvingProtocol.endBlock();
        return endBlock <= block.number ? endBlock : block.number;
    }

    /**
     * @notice Returns the reward amount per share.
     */
    function rewardPerShare() public view returns (uint256 reward) {
        reward = rewardPerShareStored;

        if (totalShare > 0) {
            uint256[] memory halvingBlocks = halvingProtocol.halvingBlocks();
            uint256 targetBlock = lastBlockRewardApplicable();
            uint256 tmpUpdatedBlock = lastUpdatedBlock < halvingProtocol.genesisBlock()
                ? halvingProtocol.genesisBlock() - 1
                : lastUpdatedBlock;

            for (uint256 i = 0; i < halvingBlocks.length; ++i) {
                if (
                    halvingBlocks[i] > tmpUpdatedBlock &&
                    halvingBlocks[i] <= targetBlock
                ) {
                    // Calculate reward before halving
                    // before-halving duration (halvingBlocks[i] - tmpUpdatedBlock - 1)
                    reward +=
                        (rewardPerBlockOf(i) *
                            (halvingBlocks[i] - tmpUpdatedBlock - 1) *
                            1e18) /
                        totalShare;
                    tmpUpdatedBlock = halvingBlocks[i] - 1;
                }
            }

            // Calculate reward after halving
            // after-halving duration (targetBlock - tmpUpdatedBlock)
            if (tmpUpdatedBlock < targetBlock) {
                uint256 _rewardPerBlock = block.number >
                    halvingProtocol.endBlock()
                    ? rewardPerBlockOf(halvingBlocks.length)
                    : rewardPerBlock();
                reward +=
                    (_rewardPerBlock * (targetBlock - tmpUpdatedBlock) * 1e18) /
                    totalShare;
            }
        }
    }

    /**
     * @notice Returns the current reward amount per block.
     */
    function rewardPerBlock() public view returns (uint256 reward) {
        reward = (halvingProtocol.currentRewardPerBlock() * allocation) / 10000;
    }

    /**
     * @notice Returns the reward amount per block for a specific halving number.
     * @param halvingNum The halving number.
     */
    function rewardPerBlockOf(
        uint256 halvingNum
    ) public view returns (uint256 reward) {
        if (halvingNum > halvingProtocol.halvingBlocks().length) {
            revert InvalidNumber(halvingNum);
        }
        reward =
            (halvingProtocol.rewardPerBlockOf(halvingNum) * allocation) /
            10000;
    }

    /**
     * @notice Returns the current total remaining reward amount.
     */
    function totalRemainReward() public view returns (uint256 remains) {
        if (initInputBlock < halvingProtocol.genesisBlock()) {
            revert InactiveProtocol();
        }

        uint256[] memory halvingBlocks = halvingProtocol.halvingBlocks();
        uint256 lastBlock = block.number;
        uint256 tmpBlock = initInputBlock;

        for (uint256 i = 0; i < halvingBlocks.length; ++i) {
            if (lastBlock >= halvingBlocks[i]) {
                // Calculate reward before halving
                remains += rewardPerBlockOf(i) * (halvingBlocks[i] - tmpBlock);
                tmpBlock = halvingBlocks[i];
            }
        }

        if (tmpBlock <= lastBlock) {
            uint256 _rewardPerBlock = block.number > halvingProtocol.endBlock()
                ? rewardPerBlockOf(halvingBlocks.length)
                : rewardPerBlock();
            remains += _rewardPerBlock * (lastBlock - tmpBlock + 1);
        }

        remains -= claimedReward;
    }

    function _updateVotes(
        address caller,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        votesOf[caller] = newVotes;
        emit UpdateVotes(caller, oldVotes, newVotes);
    }

    function _updateReward(address account) internal {
        rewardPerShareStored = rewardPerShare();
        lastUpdatedBlock = lastBlockRewardApplicable();

        if (account != address(0)) {
            shareInfos[account].reward = earned(account);
            shareInfos[account].userRewardPerSharePaid = rewardPerShareStored;
        }
    }

    function _setAllocation(uint256 allocation_) internal {
        if (allocation_ > 10000) {
            revert InvalidNumber(allocation_);
        }

        uint256 oldAlloc = allocation;
        allocation = allocation_;
        emit Allocate(oldAlloc, allocation_);
    }

    function _validateCodeSize(
        address addr
    ) internal view returns (uint32 size) {
        assembly {
            size := extcodesize(addr)
        }
    }
}