// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@erc721a/contracts/ERC721A.sol";

contract MockERC721A is ERC721A {
    constructor() ERC721A ("NFT", "NFT") {
        _mint(msg.sender, 5);
    }
}