// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/governance/utils/Votes.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interface/IVotingERC721.sol';
import './interface/IVotingERC721Descriptor.sol';

contract VotingERC721 is 
    IVotingERC721,
    ERC721Burnable,
    ERC721Enumerable,
    Votes,
    Ownable
{
    address public descriptor;
    uint256 public latestId;
    string public commonUri;

    mapping(address => bool) public minters;

    constructor(string memory name_, string memory symbol_, string memory uri_, address minter_) 
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        EIP712(name_, "v1")
    {
        commonUri = uri_;
        minters[minter_] = true;
    }

    function mint(address to, uint256 votes) external override {
        address caller = msg.sender;

        if (minters[caller]) {
            revert Unauthorized(caller);
        }

        _safeMint(to, ++latestId);
        _transferVotingUnits(address(0), to, votes);
    }

    function preMint(MintParam[] calldata params) external onlyOwner {
        if (latestId > 0) {
            revert PreMintingIsAlreadyDone();
        }

        for (uint256 i = 0; i < params.length; ++i) {
            _safeMint(params[i].account, ++latestId);
            _transferVotingUnits(address(0), params[i].account, params[i].votes);
        }
    }

    function setMinter(address addr, bool trueOrFalse) external onlyOwner {
        if (minters[addr] == trueOrFalse) {
            if (trueOrFalse) {
                revert AlreadyHasRole(addr);
            } else {
                revert AlreadyHasNoRole(addr);
            }
        }

        minters[addr] = trueOrFalse;
    }

    function setDescriptor(address descriptor_) external onlyOwner {
        if(descriptor != address(0)) {
            revert AlreadyExistDescriptor();
        }

        if (_validateCodeSize(descriptor_) == 0) {
            revert InvalidAddress(descriptor_);
        }

        descriptor = descriptor_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        if (descriptor != address(0)) {
            return IVotingERC721Descriptor(descriptor).tokenURI(this, tokenId);
        } else {
            return commonUri;
        }
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _validateCodeSize(address addr) internal view returns (uint32 size) {
        assembly {
            size := extcodesize(addr)
        }
    }
}