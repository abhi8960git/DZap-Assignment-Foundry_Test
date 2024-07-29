// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {StakingNFT} from '../src/NftTokenContract.sol';

contract StakingNFTTest is Test {
    StakingNFT private nftContract;
    address private owner;
    address private user;

    function setUp() public {
        owner = address(this);  // The owner is the address deploying the contract
        user = address(0x123); // A user address for testing
        
        nftContract = new StakingNFT("MyNFT", "NFT");
    }

    function testMintToken() public {
        // Mint a new token to the user
        nftContract.safeMint(user);

        // Verify the token ownership
        assertEq(nftContract.ownerOf(0), user);
    }


}
