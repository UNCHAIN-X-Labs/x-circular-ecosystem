// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}