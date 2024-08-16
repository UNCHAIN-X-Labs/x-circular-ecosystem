// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import '../common/ICommonError.sol';

interface IVotingERC721 is ICommonError {
    struct MintParam {
        address account;
        uint256 votes;
    }

    error AlreadyExistDescriptor();
    error AlreadyHasRole(address addr);
    error AlreadyHasNoRole(address addr);
    error PreMintingIsAlreadyDone();

    function mint(address to, uint256 votes) external;
}