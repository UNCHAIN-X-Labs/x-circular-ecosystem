// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

interface ICommonError {
    error Unauthorized(address caller);
    error InvalidAddress(address input);
    error InvalidNumber(uint256 input);
}