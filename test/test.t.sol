// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {StakingNFT} from "../src/NftTokenContract.sol";
import {RewardToken} from "../src/RewardTokenContract.sol";
import {NFTStaking} from "../src/NftStakingContract.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract StakingNFTTest is Test {
    StakingNFT private nftContract;
    RewardToken private rewardToken;
    NFTStaking private nftStaking;
    address private owner;
    address private user;
    uint256 initialSupply = 1000 * 10 ** 18;
    uint256 rewardRate = 1e18; // reward rate 1 token per seconed
    uint256 unbondingPeriod = 100; // unbonding period in seconds
    uint256 rewardClaimDelay = 50; //  reward claim delay in seconds

    function setUp() public {
        owner = address(this); // The owner is the address deploying the contract
        user = address(0x123);

        // Deploy the NFT and ERC20 token contracts
        nftContract = new StakingNFT("MyNFT", "NFT");
        rewardToken = new RewardToken("RewardToken", "RTK", initialSupply);

        // Deploy the NFTStaking contract using the UUPS proxy pattern
        NFTStaking impl = new NFTStaking();
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        nftStaking = NFTStaking(address(proxy));

        // Initialize the NFTStaking contract
        nftStaking.initialize(
            IERC20(address(rewardToken)),
            IERC721(address(nftContract)),
            rewardRate,
            unbondingPeriod,
            rewardClaimDelay
        );
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

    function testInitialize() public view {
        assertEq(address(nftStaking.rewardToken()), address(rewardToken));
        assertEq(address(nftStaking.nftToken()), address(nftContract));
        assertEq(nftStaking.rewardRate(), rewardRate);
        assertEq(nftStaking.unbondingPeriod(), unbondingPeriod);
        assertEq(nftStaking.rewardClaimDelay(), rewardClaimDelay);
    }

    function testStakeNFT() public {
        // Mint a new token to the user
        nftContract.safeMint(user);

        // Simulate user context
        vm.startPrank(user);

        // Approve the staking contract to transfer user's NFT
        nftContract.approve(address(nftStaking), 0);

        // Stake the NFT
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        nftStaking.stake(tokenIds);

        // Stop user context
        vm.stopPrank();
        console.log(user);

        // Verify the NFT is staked
        assertEq(nftContract.ownerOf(0), address(nftStaking));
        (address owner, , , ) = nftStaking.stakedNFTs(0);
        assertEq(owner, user);
    }

    function testUnstakeNFT() public {
        // Mint a new NFT to the user
        nftContract.safeMint(user);

        // Simulate user context
        vm.startPrank(user);

        // Approve the staking contract to transfer user's NFT
        nftContract.approve(address(nftStaking), 0);

        // Stake the NFT
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        nftStaking.stake(tokenIds);

        // Unstake the NFT
        nftStaking.unstake(tokenIds);

        // Stop user context
        vm.stopPrank();

        // Verify the NFT is in unbonding state
        (
            address owner,
            uint256 tokenId,
            uint256 stakedFromBlock,
            uint256 rewardDebt
        ) = nftStaking.stakedNFTs(0);
        assertEq(owner, user);
        assertEq(nftStaking.unbondingStartBlock(0), block.number);

        // Fast forward time to after the unbonding period
        vm.roll(block.number + unbondingPeriod);

        // Simulate user context again for withdrawal
        vm.startPrank(user);

        // Withdraw the NFT
        nftStaking.withdraw(tokenIds);

        // Stop user context
        vm.stopPrank();

        // Verify the NFT is returned to the user
        assertEq(nftContract.ownerOf(0), user);
        // Verify the unbondingStartBlock is reset
        assertEq(nftStaking.unbondingStartBlock(0), 0);
    }

    function testClaimRewardsDuringStaking() public {
        // Mint a new NFT to the user
        nftContract.safeMint(user);

        // Simulate user context
        vm.startPrank(user);

        // Approve the staking contract to transfer user's NFT
        nftContract.approve(address(nftStaking), 0);

        // Stake the NFT
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        nftStaking.stake(tokenIds);

        // Stop user context
        vm.stopPrank();

        // Fast forward time to accumulate rewards and pass the reward claim delay
        uint256 rewardDuration = 60; // Number of blocks to simulate reward accumulation
        uint256 totalDuration = rewardDuration + rewardClaimDelay; // Include reward claim delay period
        vm.roll(block.number + totalDuration);

        // Mint reward tokens to the staking contract
        uint256 mintAmount = 1000 * 10 ** 18;
        rewardToken.mint(address(nftStaking), mintAmount);

        // Simulate user context again for claiming rewards
        vm.startPrank(user);

        // Claim rewards
        nftStaking.claimRewards();

        // Stop user context
        vm.stopPrank();

        // Calculate the expected rewards
        uint256 expectedRewards = totalDuration * rewardRate; // Calculate expected rewards based on reward rate and duration

        // Log expected and actual rewards for debugging
        console.log("Expected Rewards:", expectedRewards);
        console.log("Actual Rewards:", rewardToken.balanceOf(user));

        // Verify the rewards were claimed correctly
        assertEq(rewardToken.balanceOf(user), expectedRewards);
    }

    function testUpdateRewardRate() public {
        // Set a new reward rate
        uint256 newRewardRate = 2e18; // 2 tokens per block
        nftStaking.updateRewardRate(newRewardRate);

        // Verify the reward rate is updated
        assertEq(nftStaking.rewardRate(), newRewardRate);
    }

    function testUpdateUnbondingPeriod() public {
        // Set a new unbonding period
        uint256 newUnbondingPeriod = 200; // 200 blocks
        nftStaking.updateUnbondingPeriod(newUnbondingPeriod);

        // Verify the unbonding period is updated
        assertEq(nftStaking.unbondingPeriod(), newUnbondingPeriod);
    }

    function testUpdateRewardClaimDelay() public {
        // Set a new reward claim delay period
        uint256 newRewardClaimDelay = 100; // 100 blocks
        nftStaking.updateRewardClaimDelay(newRewardClaimDelay);

        // Verify the reward claim delay is updated
        assertEq(nftStaking.rewardClaimDelay(), newRewardClaimDelay);
    }

    // function testPauseAndUnpause() public {
    //     // Pause the contract
    //     nftStaking.pause();

    //     // Verify the contract is paused
    //     (bool success, ) = address(nftStaking).call(
    //         abi.encodeWithSignature("stake(uint256[])")
    //     );
    //     assertEq(success, false);

    //     // Unpause the contract
    //     nftStaking.unpause();

    //     // Verify the contract is unpaused
    //     (success, ) = address(nftStaking).call(
    //         abi.encodeWithSignature("stake(uint256[])")
    //     );
    //     assertEq(success, true);
    // }
}
