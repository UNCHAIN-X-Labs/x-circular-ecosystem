// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/governance/utils/Votes.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interface/IVotingERC721.sol';
import './interface/IVotingERC721Descriptor.sol';

/**
 * @title VotingERC721
 * @notice {VotingERC721} is the agenda voting rights NFT to be used in Unchain X governance.
 * The pre-minted NFT, which is minted only once, is a launchpad referral reward.
 * After that, new NFTs will only be created within the burn protocol.​
 */
contract VotingERC721 is 
    IVotingERC721,
    ERC721Burnable,
    ERC721Enumerable,
    Votes,
    Ownable
{
    /// @notice The address of the token descriptor contract, which handles generating token URIs for voting tokens
    address public descriptor;
    /// @notice The ID of the latest token that minted. It will be skips 0.
    uint256 public latestId;
    /// @notice The common token URI before reveal.
    string public commonUri;
    /// @notice The Addresses with minting authority.

    /** 
     * @notice The Addresses with minting authority.
     * This authority will be granted only to the XRecycling contract and the contract that separates/combines votes.
     */
    mapping(address => bool) public minters;

    /**
     * @notice Returns the number of voting rights allocated to each token.
     */
    mapping(uint256 => uint256) public votesOf;

    constructor(string memory name_, string memory symbol_, string memory uri_, address minter_) 
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        EIP712(name_, "v1")
    {
        commonUri = uri_;
        minters[minter_] = true;
    }

    /// @inheritdoc IVotingERC721
    function mint(address to, uint256 votes) external override {
        address caller = msg.sender;

        if (minters[caller]) {
            revert Unauthorized(caller);
        }

        _mintAndAllocateVotes(to, votes);
    }

    /**
     * @notice Pre-minting for launchpad referral rewards.
     * It should be executed only once for the first time by owner.
     * @param params The information about the wallet address to receive the NFT and the number of voting rights to be allocated to the token.
     */
    function preMint(MintParam[] calldata params) external onlyOwner {
        if (latestId > 0) {
            revert PreMintingIsAlreadyDone();
        }

        for (uint256 i = 0; i < params.length; ++i) {
            _mintAndAllocateVotes(params[i].account, params[i].votes);
        }
    }

    /**
     * @notice Grant the minter authority.
     * It should be executed only once for the first time by owner.
     * @param ca The target contract address
     * @param trueOrFalse Whether to grant the authority.
     */
    function setMinter(address ca, bool trueOrFalse) external onlyOwner {
        if (_validateCodeSize(ca) == 0) {
            revert InvalidAddress(ca);
        }

        if (minters[ca] == trueOrFalse) {
            if (trueOrFalse) {
                revert AlreadyHasRole(ca);
            } else {
                revert AlreadyHasNoRole(ca);
            }
        }

        minters[ca] = trueOrFalse;
    }

    /**
     * @notice Set the descriptor contract address.
     * It should be executed only once for the first time by owner.
     * @param descriptor_ The contract address to describe the tokenURI.
     */
    function setDescriptor(address descriptor_) external onlyOwner {
        if(descriptor != address(0)) {
            revert AlreadyExistDescriptor();
        }

        if (_validateCodeSize(descriptor_) == 0) {
            revert InvalidAddress(descriptor_);
        }

        descriptor = descriptor_;
    }

    /**
     * @notice Returns the tokenURI.
     * If the descriptor is the zero address, it shows a common URI in an unrevealed state.
     * @param tokenId The token's ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        if (descriptor != address(0)) {
            return IVotingERC721Descriptor(descriptor).tokenURI(this, tokenId);
        } else {
            return commonUri;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        address previousOwner = ERC721Enumerable._update(to, tokenId, auth);

        _transferVotingUnits(previousOwner, to, _getVotingUnits(previousOwner));

        return previousOwner;
    }

    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account);
    }

    function _increaseBalance(address account, uint128 amount) internal virtual override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._increaseBalance(account, amount);
    }

    function _mintAndAllocateVotes(address to, uint256 votes) internal {
        _safeMint(to, ++latestId);
        _transferVotingUnits(address(0), to, votes);
        votesOf[latestId] = votes;
    }

    function _validateCodeSize(address addr) internal view returns (uint32 size) {
        assembly {
            size := extcodesize(addr)
        }
    }
}