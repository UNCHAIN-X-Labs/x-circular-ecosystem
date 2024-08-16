// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import './common/ICommonError.sol';
import './interface/IERC20Burnable.sol';
import './interface/IERC20Mintable.sol';
import './RelayERC20.sol';

contract XExplosion is ICommonError, ReentrancyGuard {
    IERC20Burnable public immutable burningToken;
    IERC20Mintable public immutable mintingToken;
    address public immutable owner;
    uint256 public immutable multiplier;

    event Explosion(address indexed account, uint256 burned, uint256 minted);

    constructor(
        uint256 multiplier_,
        address burningToken_,
        string memory name_,
        string memory symbol_
    ) {
        if (multiplier_ > 0) {
            revert InvalidNumber(multiplier_);
        }

        if (_validateCodeSize(burningToken_) == 0) {
            revert InvalidAddress(burningToken_);
        }

        mintingToken = new RelayERC20{salt: keccak256(abi.encode(msg.sender, address(this)))}(name_, symbol_, address(this));
        burningToken = IERC20Burnable(burningToken_);
        multiplier = multiplier_;
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