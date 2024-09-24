// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IXPlosion} from './interface/IXPlosion.sol';
import {IERC20Burnable} from './interface/IERC20Burnable.sol';
import {IERC20Mintable} from './interface/IERC20Mintable.sol';
import {XParticle} from './XParticle.sol';
import {CommonAuth} from './common/CommonAuth.sol';

/**
 * @title XPlosion
 * @notice {XPlosion} is a contract that burns UNX tokens to generate new tokens.
 * The new tokens are created in proportion to the amount of UNX burned, according to a specific ratio.
 */
contract XPlosion is IXPlosion, CommonAuth, ReentrancyGuard {
    /// @notice The token to be burned should be the UNX Token.
    IERC20Burnable public immutable burningToken;
    /// @notice The token to be minted.
    IERC20Mintable public immutable mintingToken;
    /// @notice A multiple of the quantity of newly minted tokens.
    uint256 public immutable multiplier;
    /// @inheritdoc IXPlosion
    uint256 public requiredBurningAmount;
    /// @inheritdoc IXPlosion
    uint256 public totalBurnedAmount;
    
    /// @inheritdoc IXPlosion
    mapping(address => uint256) public burningAmountOf;
    /// @inheritdoc IXPlosion
    mapping(address => uint256) public referralRewards;

    constructor(
        uint256 multiplier_,
        address burningToken_,
        string memory name_,
        string memory symbol_,
        uint256 requiredBurningAmount_
    ) CommonAuth(msg.sender) {
        if (multiplier_ == 0) {
            revert InvalidNumber(multiplier_);
        }

        if (_validateCodeSize(burningToken_) == 0) {
            revert InvalidAddress(burningToken_);
        }

        burningToken = IERC20Burnable(burningToken_);
        mintingToken = new XParticle{salt: keccak256(abi.encode(msg.sender, address(this)))}(name_, symbol_, address(this));
        multiplier = multiplier_;
        requiredBurningAmount = requiredBurningAmount_;
    }

    /// @inheritdoc IXPlosion
    function explode(address inviter, uint256 amount) external nonReentrant returns (uint256 mintedAmount) {
        address caller = msg.sender;

        if (inviter != address(0)) {
            if (!validateInviter(caller, inviter)) {
                revert InvalidAddress(inviter);
            }

            mintedAmount = amount * multiplier * 101 / 100;
            uint256 referralReward = mintedAmount / 100;
            
            if (referralReward > 0) {
                IERC20Mintable(mintingToken).mint(inviter, referralReward);
                referralRewards[inviter] += referralReward;
            }

            emit Referral(inviter, caller, amount, referralReward);
        } else {
            mintedAmount = amount * multiplier;
        }

        IERC20Burnable(burningToken).burnFrom(caller, amount);
        IERC20Mintable(mintingToken).mint(caller, mintedAmount);

        burningAmountOf[caller] += amount;
        totalBurnedAmount += amount;

        emit Explosion(caller, amount, mintedAmount);
    }

    /// @inheritdoc IXPlosion
    function setRequiredBurningAmount(uint256 requiredBurningAmount_) external onlyOwnerOrExecutor {
        requiredBurningAmount = requiredBurningAmount_;
    }

    /// @inheritdoc IXPlosion
    function validateInviter(address invitee, address inviter) public view returns (bool result) {
        uint256 burnigAmountOfInviter = burningAmountOf[inviter];

        if (invitee != inviter &&
            _validateCodeSize(inviter) == 0 &&
            burnigAmountOfInviter >= requiredBurningAmount
        ) {
            result = true;
        }
    }

    function _validateCodeSize(address addr) internal view returns (uint32 size) {
        assembly {
            size := extcodesize(addr)
        }
    }
}