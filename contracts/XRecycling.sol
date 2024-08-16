// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import './interface/IXRecycling.sol';
import './interface/IHalvingProtocol.sol';
import './interface/IERC20Burnable.sol';
import './interface/IVotingERC721.sol';
import './VotingERC721.sol';
import './common/CommonAuth.sol';

contract XRecycling is IXRecycling, CommonAuth, ReentrancyGuard {
    IHalvingProtocol public immutable halvingProtocol;
    IERC20Burnable public immutable burningToken;
    IVotingERC721 public immutable votingToken;
    uint256 public immutable votesMultiplier;

    bool public actived;
    // apply 2 decimals. 100.00 % => 10000
    uint256 public allocation;
    uint256 public lastUpdatedBlock;
    uint256 public rewardPerShareStored;
    uint256 public totalShare;
    uint256 public claimedReward;
    uint256 public initInputBlock;

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

    function initialize(uint256 allocation_) external onlyOwnerOrExecutor {
        if(actived) {
            revert AlreadyInitialized();
        }
        _setAllocation(allocation_);
        actived = true;
        emit Activate();
    }

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
        votingToken.mint(caller, amount * votesMultiplier);

        shareInfos[caller].share += amount;
        totalShare += amount;

        expectedTotalShare = totalShare;
        expectedShare = shareInfos[caller].share;

        emit AddShare(caller, amount);
    }

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

    function earned(address account) public view returns (uint256) {
        ShareInfo memory shareInfo = shareInfos[account];
        return (shareInfo.share * (rewardPerShare() - shareInfo.userRewardPerSharePaid)) / 1e18 + shareInfo.reward;
    }

    function lastBlockRewardApplicable() public view returns (uint256) {
        uint256 endBlock = halvingProtocol.endBlock();
        return endBlock <= block.number ? endBlock : block.number;
    }    

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

    function rewardPerBlock() public view returns (uint256 reward) {
        reward = halvingProtocol.currentRewardPerBlock() * allocation / 10000;
    }

    function rewardPerBlockOf(uint256 halvingNum) public view returns (uint256 reward) {
        if(halvingNum > halvingProtocol.halvingBlocks().length) {
            revert InvalidNumber(halvingNum);
        }
        reward = halvingProtocol.rewardPerBlockOf(halvingNum) * allocation / 10000;
    }

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