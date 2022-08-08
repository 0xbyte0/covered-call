// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@erc721a/contracts/ERC721A.sol";

contract coveredCallNFT is ERC721A("CallNFT", "CLN") {

    uint256 public constant MAX_TOKENS = type(uint256).max;

    constructor() {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint _numTokens) public {
        require(totalSupply() + _numTokens <= MAX_TOKENS, "MAX_TOKENS_EXCEEDED");
        unchecked {
            for (uint i = 0; i < _numTokens; i++) {
                _safeMint(msg.sender, totalSupply() + 1);
            }
        }
    }

    // function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
    //     uint256 tokenCount = balanceOf(_owner);
    //     if (tokenCount == 0) {
    //         return new uint256[](0);
    //     } else {
    //         uint256[] memory tokensIndices = new uint256[](tokenCount);
    //         unchecked {
    //             for (uint256 i = 0; i < tokenCount; i++) {
    //                 tokensIndices[i] = tokenOfOwnerByIndex(_owner, i);
    //             }
    //         }
    //         return tokensIndices;
    //     }
    // }
    
}