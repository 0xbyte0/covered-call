// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@solmate/tokens/ERC721.sol";

/// modified from: https://github.com/outdoteth/cally/blob/main/src/CallyNft.sol

abstract contract coveredCallNFT is ERC721("CCall", "CAL") {
    function _mint(address to, uint256 id) internal override {
        require(to != address(0), "invalid recipient");
        require(_ownerOf[id] == address(0), "already minted");

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    // burns a token without checking owner address is not 0
    // and removes balanceOf modifications
    function _burn(uint256 id) internal override {
        address owner = _ownerOf[id];

        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    // forceTransfer option position NFT out of owner's wallet and give to new buyer
    function _forceTransfer(address to, uint256 id) internal {
        require(to != address(0), "invalid recipient");

        address from = _ownerOf[id];
        _ownerOf[id] = to;
        delete getApproved[id];

        emit Transfer(from, to, id);
    }
}