// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import './interface/IERC20Burnable.sol';
import './interface/IERC20Mintable.sol';
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract XExplosion is ReentrancyGuard {
    address public burningToken;
    address public mintingToken;
    address public immutable owner;
    uint256 public immutable multiplier;

    event Explosion(address indexed account, uint256 burned, uint256 minted);

    error AlreadyInitialized();
    error Unauthorized(address caller);
    error InvalidAddress(address input);

    constructor(uint256 multiplier_) {
        require(multiplier_ > 0);
        multiplier = multiplier_;
    }

    function initialize(address burningToken_, address mintingToken_) external {
        if(msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }

        if(burningToken != address(0) || mintingToken != address(0)) {
            revert AlreadyInitialized();
        }

        if(_validateCodeSize(burningToken_) == 0) {
            revert InvalidAddress(burningToken_);
        }

        if(_validateCodeSize(mintingToken_) == 0) {
            revert InvalidAddress(mintingToken_);
        }

        burningToken = burningToken_;
        mintingToken = mintingToken_;
    }

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