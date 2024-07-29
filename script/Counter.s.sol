// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StakingNFT} from "../src/NftTokenContract.sol";
import {RewardToken} from "../src/RewardTokenContract.sol";
import {NFTStaking} from "../src/NftStakingContract.sol";

contract DeployNFTStaking is Script {
    StakingNFT private stakingNFT;
    RewardToken private rewardToken;
    NFTStaking private nftStaking;

    uint256 private initialSupply = 1000 * 10 ** 18;
    uint256 private rewardRate = 1e18;
    uint256 private unbondingPeriod = 1000;
    uint256 private rewardClaimDelay = 100;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy ERC721 NFT Token
        stakingNFT = new StakingNFT("mYToken", "Mk");

        // Deploy ERC20 Reward Token
        rewardToken = new RewardToken("RewardToken", "RTK", initialSupply);

        // Deploy NFTStaking contract
        nftStaking = new NFTStaking();

        // Initialize NFTStaking contract
        nftStaking.initialize(
            rewardToken,
            stakingNFT,
            rewardRate,
            unbondingPeriod,
            rewardClaimDelay
        );

        vm.stopBroadcast();
    }
}
