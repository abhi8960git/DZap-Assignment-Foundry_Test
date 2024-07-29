// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {StakingNFT} from "../src/NftTokenContract.sol";
import {RewardToken} from "../src/RewardTokenContract.sol";

contract StakingNFTTest is Test {
    StakingNFT private nftContract;
    RewardToken private rewardToken;
    address private owner;
    address private user;
    uint256 initialSupply = 1000 * 10 ** 18;

    function setUp() public {
        owner = address(this); // The owner is the address deploying the contract
        user = address(0x123);

        nftContract = new StakingNFT("MyNFT", "NFT");
        rewardToken = new RewardToken("RewardToken", "RTK", initialSupply);
    }

    function testMintToken() public {
        // Mint a new token to the user
        nftContract.safeMint(user);

        // Verify the token ownership
        assertEq(nftContract.ownerOf(0), user);
    }

    function testERC20Token() public {
        // mint a new token to user
        rewardToken.mint(user, initialSupply);

        // verify the token balance
        assertEq(rewardToken.balanceOf(user), initialSupply);
    }
}
