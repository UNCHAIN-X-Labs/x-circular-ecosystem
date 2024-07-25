// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

interface IERC20Burnable {
    function burn(uint256 value) external;
    function burnFrom(address account, uint256 value) external;
}