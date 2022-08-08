// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "src/coveredCall.sol";
import "src/coveredCallNFT.sol";
import "./mocks/ERC721A.sol";

contract TestContract is Test {
    coveredCallNFT myCoveredCallNFT;
    coveredCall myCoveredCall;
    MockERC721A mockNFT;

    function setUp() public {
        mockNFT = new MockERC721A();
        myCoveredCallNFT = new coveredCallNFT();
        myCoveredCall = new coveredCall();
    }

    function testNewVault() public {
        uint tokenId = 1;
        mockNFT.approve(address(myCoveredCall), tokenId);
        myCoveredCall.newVault(tokenId, address(mockNFT), 1 days, 3 ether);

    }

    function testFoo(uint256 x) public {
        vm.assume(x < type(uint128).max);
        assertEq(x + x, x * 2);
    }
}
