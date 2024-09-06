// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20Mintable} from './interface/IERC20Mintable.sol';
import {ICommonError} from './common/ICommonError.sol';

/**
 * @title RelayERC20
 * @notice {RelayERC20} is minted at a fixed rate when UNX is burned within the Unchain X ecosystem.
 */
contract RelayERC20 is IERC20Mintable, ERC20Burnable, ICommonError {
    /// @dev The minter should be a contract implementing the UNX burning process.
    address public immutable minter;
    
    constructor(string memory name_, string memory symbol_, address minter_) ERC20(name_, symbol_) {
        if (minter_ == address(0)) {
            revert InvalidAddress(minter_);
        }
        minter = minter_;
    }

    /**
     * @notice Mint a token.
     * @dev Only execute by minter.
     * @param to The receiver.
     * @param amount The amount to be minted.
     */
    function mint(address to, uint256 amount) external {
        if(msg.sender != minter) {
            revert Unauthorized(msg.sender);
        }
        _mint(to, amount);
    }
}