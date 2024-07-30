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

        // Verify the NFT is staked
        assertEq(nftContract.ownerOf(0), address(nftStaking));
        (address owner,,,) = nftStaking.stakedNFTs(0);
        assertEq(owner, user);
    }


}

  
