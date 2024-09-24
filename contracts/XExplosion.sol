// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ICommonError} from './common/ICommonError.sol';
import {IERC20Burnable} from './interface/IERC20Burnable.sol';
import {IERC20Mintable} from './interface/IERC20Mintable.sol';
import {RelayERC20} from './RelayERC20.sol';

/**
 * @title XExplosion
 * @notice {XExplosion} is a contract that burns UNX tokens to generate new tokens.
 * The new tokens are created in proportion to the amount of UNX burned, according to a specific ratio.
 */
contract XExplosion is ICommonError, ReentrancyGuard {
    /// @notice The token to be burned should be the UNX Token.
    IERC20Burnable public immutable burningToken;
    /// @notice The token to be minted.
    IERC20Mintable public immutable mintingToken;
    /// @notice A multiple of the quantity of newly minted tokens.
    uint256 public immutable multiplier;

    /**
     * @notice This event should be emitted when the explode function is executed.
     * @param account The account that executed.
     * @param burned The amount of UNX tokens burned.
     * @param minted The amount of new tokens minted.
     */
    event Explosion(address indexed account, uint256 burned, uint256 minted);

    constructor(
        uint256 multiplier_,
        address burningToken_,
        string memory name_,
        string memory symbol_
    ) {
        if (multiplier_ == 0) {
            revert InvalidNumber(multiplier_);
        }

        if (_validateCodeSize(burningToken_) == 0) {
            revert InvalidAddress(burningToken_);
        }

        burningToken = IERC20Burnable(burningToken_);
        mintingToken = new RelayERC20{salt: keccak256(abi.encode(msg.sender, address(this)))}(name_, symbol_, address(this));
        multiplier = multiplier_;
    }

    /**
     * @notice Burn UNX to receive new tokens.
     * Need to approve the UNX tokens for this contract in advance.
     * @param amount The amount of tokens to be burned​.
     */
    function explode(uint256 amount) external nonReentrant returns (uint256 mintedAmount) {
        address caller = msg.sender;
        IERC20Burnable(burningToken).burnFrom(caller, amount);

        mintedAmount = amount * multiplier;
        IERC20Mintable(mintingToken).mint(caller, mintedAmount);

        emit Explosion(caller, amount, mintedAmount);
    }

    function _validateCodeSize(address addr) internal view returns (uint32 size) {
        assembly {
            size := extcodesize(addr)
        }
    }
}