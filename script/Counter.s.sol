// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StakingNFT} from '../src/NftTokenContract.sol';


contract CounterScript is Script {
   StakingNFT public counter;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        counter = new StakingNFT("mYToken", "Mk");

        vm.stopBroadcast();
    }
}
