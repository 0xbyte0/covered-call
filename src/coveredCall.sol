// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./counter.sol";
import "./coveredCallNFT.sol";

/// @title A minimal ERC721 covered call vaults
/// @author 0xosas
/// @notice ERC721 covered call vaults
contract coveredCall is Ownable, IERC721Receiver{ 
    using Counters for Counters.Counter;

    uint256 private constant BITWIDTH_TOKEN_ADDRESS = 160;

    uint256 private constant BITWIDTH_TOKEN_ID = 14;

    uint256 private constant BITWIDTH_TOKEN_DATA = BITWIDTH_TOKEN_ID + BITWIDTH_TOKEN_ADDRESS;

    uint256 private constant BITWIDTH_DURATION = 6; 

    uint256 private constant BITWIDTH_STRIKE_PRICE = 60;

    uint256 private constant BITWIDTH_CALL_DATA = BITWIDTH_STRIKE_PRICE + BITWIDTH_DURATION;

    uint256 private constant BITWIDTH_AUX = 4;

    uint256 private constant BITMASK_TOKEN_ADDRESS = (1 << BITWIDTH_TOKEN_ADDRESS) - 1;

    uint256 private constant BITMASK_TOKEN_ID = ((1 << BITWIDTH_TOKEN_ID) - 1);

    uint256 private constant BITMASK_TOKEN_DATA = (1 << BITWIDTH_TOKEN_DATA) - 1;

    uint256 private constant BITMASK_DURATION = ((1 << BITWIDTH_DURATION) - 1);

    uint256 private constant BITMASK_STRIKE_PRICE = ((1 << BITWIDTH_STRIKE_PRICE) - 1);

    uint256 private constant BITMASK_CALL_DATA = ((1 << BITWIDTH_CALL_DATA) - 1);

    Counters.Counter private _s_vaultId;

    uint256 internal s_defaultFeeRate = 10;

    mapping(uint256 => uint256) internal s_vault;

    function setFee(uint256 _newFee) external onlyOwner {
        require(_newFee < 15, "fee must not exceed 15%");
        s_defaultFeeRate = _newFee;
    }

    function newVault(
        uint256 tokenId,
        address tokenAddr,
        uint256 duration,
        uint256 strikePrice
    ) external returns(uint256 vaultId) {
        require(tokenId > 0, "invalid tokenId");
        require(duration > 0, "duration too small");
        require(tokenAddr != address(0), "invalid token address");
        require(strikePrice > 0, "strikePrice too small");

        uint256 token_data = (uint256(uint160(tokenAddr)) << BITWIDTH_TOKEN_ID) | tokenId;
        uint256 call_data = (strikePrice << BITWIDTH_DURATION) | duration;
        uint256 v = (call_data << BITWIDTH_TOKEN_DATA) | token_data;

        _s_vaultId.increment();
        vaultId = _s_vaultId.current();

        s_vault[vaultId] = v;

        ERC721(tokenAddr).safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function buyOption(uint256 vaultId) external payable returns (uint256 optionId) {
        require(vaultId < _s_vaultId.current(), "vault does not exists");

        uint256 vault_value = s_vault[vaultId];

    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}