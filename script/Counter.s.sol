// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StakingNFT} from "../src/NftTokenContract.sol";
import {RewardToken} from "../src/RewardTokenContract.sol";

contract CounterScript is Script {
    StakingNFT public counter;
    RewardToken private rewardToken;
    uint256 initialSupply = 1000 * 10 ** 18; 
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counter = new StakingNFT("mYToken", "Mk");
        rewardToken = new RewardToken("RewardToken", "RTK", initialSupply);

        vm.stopBroadcast();
    }
}
