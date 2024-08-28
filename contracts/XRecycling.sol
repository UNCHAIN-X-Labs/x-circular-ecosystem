// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IXRecycling} from './interface/IXRecycling.sol';
import {IHalvingProtocol} from './interface/IHalvingProtocol.sol';
import {IERC20Burnable} from './interface/IERC20Burnable.sol';
import {IVotingERC721} from './interface/IVotingERC721.sol';
import {VotingERC721} from './VotingERC721.sol';
import {CommonAuth} from './common/CommonAuth.sol';

/**
 * @title XRecycling
 * @notice {XRecycling} is a protocol contract designed to burn tokens to gain share and receive token rewards based on that share.
 * The share accumulates over time, however when rewards are claimed, the existing share is reduced proportionally to the ratio of the claimed reward to the total remaining rewards.
 * Additionally, each time add to share, earn a voting NFT.
 */
contract XRecycling is IXRecycling, CommonAuth, ReentrancyGuard {
    /// @notice
    IHalvingProtocol public immutable halvingProtocol;
    /// @notice
    IERC20Burnable public immutable burningToken;
    /// @notice
    IVotingERC721 public immutable votingToken;
    /// @notice
    uint256 public immutable votesMultiplier;

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
    /// @notice Total claimed reward amount
    uint256 public claimedReward;
    /// @notice The block number where the share was first added.
    uint256 public initInputBlock;

    /// @notice The share information per account
    mapping(address => ShareInfo) public shareInfos;

    modifier updateReward() {
        _updateReward(msg.sender);
        _;
    }

    constructor(
        address halvingProtocol_,
        address burningToken_,
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 votesMultiplier_
    ) CommonAuth(msg.sender) {
        if(_validateCodeSize(halvingProtocol_) == 0) {
            revert InvalidAddress(halvingProtocol_);
        }

        if(_validateCodeSize(burningToken_) == 0) {
            revert InvalidAddress(burningToken_);
        }

        if(votesMultiplier_ == 0) {
            revert InvalidNumber(votesMultiplier_);
        }

        halvingProtocol = IHalvingProtocol(halvingProtocol_);
        burningToken = IERC20Burnable(burningToken_);
        votingToken = new VotingERC721{salt: keccak256(abi.encode(msg.sender, address(this)))}(name_, symbol_, uri_, address(this));
        votesMultiplier = votesMultiplier_;
    }

    /**
     * @notice Set the reward allocation active status to active.​
     * It should be executed only once for the first time by owner or executor.
     * @param allocation_ UNX reward allocation
     */
    function initialize(uint256 allocation_) external onlyOwnerOrExecutor {
        if(actived) {
            revert AlreadyInitialized();
        }
        _setAllocation(allocation_);
        actived = true;
        emit Activate();
    }

    /**
     * @notice Burn tokens to add share.
     * Additionally, earn voting NFT based on the amount of tokens burned.
     * @param amount The amount of tokens to burn​
     * @return expectedTotalShare Expected total share
     * @return expectedShare Expected share
     */
    function addShare(uint256 amount) 
        external
        nonReentrant
        updateReward
        returns (uint256 expectedTotalShare, uint256 expectedShare)
    {
        if(!actived) {
            revert InactiveProtocol();
        }

        if(amount == 0) {
            revert InvalidNumber(amount);
        }

        if(initInputBlock == 0) {
            initInputBlock = block.number;
        }

        address caller = msg.sender;

        burningToken.burnFrom(caller, amount);
        votingToken.mint(caller, amount / 1e18 * votesMultiplier);

        shareInfos[caller].share += amount;
        totalShare += amount;

        expectedTotalShare = totalShare;
        expectedShare = shareInfos[caller].share;

        emit AddShare(caller, amount);
    }

    /**
     * @notice Claim reward.
     * The share will also be reduced by the same ratio as the claimed reward compared to the total reward.​
     * It will revert if the remaining share is less than the required minimum remaining share.​
     * @param minRequiredRemains Required minimum remaining share
     * @param requiredReward Required reward claim amount
     * @return remainShare The Remaining share
     * @return remainTotalShare The total remaing share
     */
    function claim(uint256 minRequiredRemains, uint256 requiredReward)
        external
        nonReentrant
        updateReward
        returns (uint256 remainShare, uint256 remainTotalShare)
    {
        address caller = msg.sender;
        ShareInfo memory shareInfo = shareInfos[caller];
        uint256 currentShare = shareInfo.share;
        uint256 remainsReward = shareInfo.reward;

        if(currentShare == 0) {
            revert DoesNotExistInfo(caller);
        }

        if(requiredReward > remainsReward) {
            revert InsufficientReward(requiredReward, remainsReward);
        }

        // Calculate reduction ratio
        uint256 quotient = totalRemainReward() / requiredReward;
        uint256 subShare = currentShare / quotient;
        remainTotalShare = totalShare - subShare;
        remainShare = currentShare - subShare;
        
        if (remainShare < minRequiredRemains) {
            revert ExceedMinRequired(minRequiredRemains, remainShare);
        }

        // Transfer reward
        halvingProtocol.transferReward(caller, requiredReward);
        shareInfos[caller].reward -= requiredReward;
        claimedReward += requiredReward;
        emit Claim(caller, requiredReward);

        // Reduce share
        shareInfos[caller].share = remainShare;
        totalShare = remainTotalShare;
        emit RemoveShare(caller, subShare);
    }

    /**
     * @notice Return dashboard Information.
     * @param account The address of user.
     */
    function dashboardInfo(address account) public view returns (DashboardInfo memory result) {
        result.earned = earned(account);
        result.totalShare = totalShare;
        result.share = shareInfos[account].share;
        result.totalClaimedReward = claimedReward;
        result.allocatedRewardPerDay = rewardPerBlock() * 28800;
    }

    /**
     * @notice Returns the currently earned reward amount.
     * @param account The address of account
     */
    function earned(address account) public view returns (uint256) {
        ShareInfo memory shareInfo = shareInfos[account];
        return (shareInfo.share * (rewardPerShare() - shareInfo.userRewardPerSharePaid)) / 1e18 + shareInfo.reward;
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
            uint256 tmpUpdatedBlock = lastUpdatedBlock;

            for(uint256 i = 0; i < halvingBlocks.length; ++i) {
                if(halvingBlocks[i] > tmpUpdatedBlock && halvingBlocks[i] <= targetBlock) {
                    // Calculate reward before halving
                    // before-halving duration (halvingBlocks[i] - tmpUpdatedBlock - 1)
                    reward += rewardPerBlockOf(i) * (halvingBlocks[i] - tmpUpdatedBlock - 1) * 1e18 / totalShare;
                    tmpUpdatedBlock = halvingBlocks[i] - 1;
                }
            }

            // Calculate reward after halving
            // after-halving duration (targetBlock - tmpUpdatedBlock)
            if(tmpUpdatedBlock < targetBlock) {
                reward += rewardPerBlock() * (targetBlock - tmpUpdatedBlock) * 1e18 / totalShare;
            }
        }
    }

    /**
     * @notice Returns the current reward amount per block.
     */
    function rewardPerBlock() public view returns (uint256 reward) {
        reward = halvingProtocol.currentRewardPerBlock() * allocation / 10000;
    }

    /**
     * @notice Returns the reward amount per block for a specific halving number.
     * @param halvingNum The halving number.
     */
    function rewardPerBlockOf(uint256 halvingNum) public view returns (uint256 reward) {
        if(halvingNum > halvingProtocol.halvingBlocks().length) {
            revert InvalidNumber(halvingNum);
        }
        reward = halvingProtocol.rewardPerBlockOf(halvingNum) * allocation / 10000;
    }

    /**
     * @notice Returns the current total remaining reward amount.
     */
    function totalRemainReward() public view returns (uint256 remains) {
        uint256[] memory halvingBlocks = halvingProtocol.halvingBlocks();
        uint256 lastBlock = block.number;
        uint256 tmpBlock = initInputBlock;

        for(uint256 i = 0; i < halvingBlocks.length; ++i) {
            if(lastBlock > halvingBlocks[i]) {
                // Calculate reward before halving
                remains += rewardPerBlockOf(i) * ((halvingBlocks[i] - 1) - tmpBlock + 1) * 1e18 / totalShare;
                tmpBlock = halvingBlocks[i];
            }
        }

        if(tmpBlock <= lastBlock) {
            remains = rewardPerBlock() * (lastBlock - tmpBlock + 1);
        }

        remains - claimedReward;
    }

    function _updateReward(address account) internal {
        rewardPerShareStored = rewardPerShare();
        lastUpdatedBlock = lastBlockRewardApplicable();

        if(account != address(0)) {
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

    function _validateCodeSize(address addr) internal view returns (uint32 size) {
        assembly {
            size := extcodesize(addr)
        }
    }
}