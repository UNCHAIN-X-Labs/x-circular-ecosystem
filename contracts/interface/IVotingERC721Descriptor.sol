  // SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import './IVotingERC721.sol';

interface IVotingERC721Descriptor {
    function tokenURI(IVotingERC721 votingNFT, uint256 tokenId) external view returns (string memory);
}