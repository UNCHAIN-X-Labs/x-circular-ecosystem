// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import './interface/IRecycling.sol';
import './interface/IHalvingProtocol.sol';
import './interface/IERC20Burnable.sol';
import './common/CommonAuth.sol';

contract XRecycling is IXRecycling, CommonAuth, ReentrancyGuard {
    IHalvingProtocol public immutable halvingProtocol;
    IERC20Burnable public immutable burningToken;

    bool public actived;
    // apply 2 decimals. 100.00 % => 10000
    uint256 public allocation;
    uint256 public lastUpdatedBlock;
    uint256 public rewardPerShareStored;
    uint256 public totalShare;

    mapping(address => ShareInfo) public shareInfos;

    modifier updateReward() {
        _updateReward(msg.sender);
        _;
    }

    constructor(address halvingProtocol_, address burningToken_) CommonAuth(msg.sender) {
        if(_validateCodeSize(halvingProtocol_) == 0) {
            revert InvalidAddress(halvingProtocol_);
        }

        if(_validateCodeSize(burningToken_) == 0) {
            revert InvalidAddress(burningToken_);
        }

        halvingProtocol = IHalvingProtocol(halvingProtocol_);
        burningToken = IERC20Burnable(burningToken_);
    }

    function initialize(uint256 allocation_) external onlyOwnerOrExecutor {
        if(actived) {
            revert AlreadyInitialized();
        }
        _setAllocation(allocation_);
        actived = true;
        emit Activate();
    }

    function addShare(uint256 amount) external nonReentrant updateReward {
        if(!actived) {
            revert InactiveProtocol();
        }

        if(amount == 0) {
            revert InvalidNumber(amount);
        }

        address caller = msg.sender;

        burningToken.burnFrom(caller, amount);
        shareInfos[caller].share += amount;
        totalShare += amount;

        emit AddShare(caller, amount);
    }

    function claim() external nonReentrant updateReward returns (uint256 reward) {
        address caller = msg.sender;
        ShareInfo memory shareInfo = shareInfos[caller];

        if(shareInfo.share == 0) {
            revert DoesNotExistInfo(caller);
        }

        if(shareInfo.reward > 0) {
            revert DoesNotExistReward(caller);
        }

        halvingProtocol.transferReward(caller, shareInfo.reward);
        emit Claim(caller, reward);

        // remove share
        delete shareInfos[caller];
        totalShare -= shareInfo.share;
        emit RemoveShare(caller, shareInfo.share);
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
                reward += (rewardPerBlock() * (targetBlock - tmpUpdatedBlock) * 1e18 / totalShare);
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