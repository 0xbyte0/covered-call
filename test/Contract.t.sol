// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./mocks/MockNFT.sol";
import "../src/coveredCall.sol";


contract TestContract is Test, ERC721Holder {
    coveredCall myCoveredCall;
    MockERC721 mockNFT;

    function setUp() public {
        mockNFT = new MockERC721("NFT", "NFT");
        myCoveredCall = new coveredCall();

        for(uint x = 0; x < 10; x++) {
            mockNFT.mint(address(this), x);
        }
    }

    function createNewVault(uint tokenId) public returns (uint256 vaultId){
        uint endsAt = block.timestamp + 1 days ;
        uint startsAt = block.timestamp;
        uint strikePrice = 3;
        mockNFT.approve(address(myCoveredCall), tokenId);
        
        vaultId = myCoveredCall.newVault(tokenId, address(mockNFT), startsAt, endsAt, strikePrice);
    }

    function testNewVault() public {
        uint tokenId = 1;
        uint startsAt = block.timestamp;
        uint endsAt = startsAt + 1 days ;
        uint strikePrice = 3;
        mockNFT.approve(address(myCoveredCall), tokenId);
        uint vaultId = myCoveredCall.newVault(tokenId, address(mockNFT), startsAt, endsAt, strikePrice);

        (uint _tokenId, address _tokenAddress, uint _endsAt, uint _startsAt, uint _strikePrice, uint _misc) = myCoveredCall.getVaultData(myCoveredCall.vaults(vaultId));
        
        assertEq(_tokenId, tokenId);
        assertEq(_tokenAddress, address(mockNFT));
        assertEq(_endsAt, endsAt);
        assertEq(_startsAt, startsAt);
        assertEq(_strikePrice, strikePrice);
    }

    function testInitiateWithdraw() public {
        uint256 vaultId = createNewVault(2);

        myCoveredCall.initiateWithdraw(vaultId);

        vm.expectRevert(bytes("already withdrawing"));
        myCoveredCall.initiateWithdraw(vaultId);
    }

    function testExercise() public {
        uint256 vaultId = createNewVault(3);

        myCoveredCall.exerciseOption(vaultId);

        vm.expectRevert(bytes("vault exercised"));
        myCoveredCall.exerciseOption(vaultId);
    }

    function testPurchaseOption() public {
        uint256 vaultId = createNewVault(4);

        myCoveredCall.purchaseOption(vaultId);
    }
}
