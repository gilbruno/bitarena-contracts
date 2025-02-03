// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {BitarenaChallenge} from "../../../src/BitarenaChallenge.sol";

contract CreateTeam is Script {
    function run(address challengeAddress, uint16 teamIndex) external {
        uint256 playerPrivateKey = vm.envUint("PRIVATE_KEY_PLAYER");
        
        vm.startBroadcast(playerPrivateKey);
        BitarenaChallenge(payable(challengeAddress)).createOrJoinTeam{value: 0.01 ether}(teamIndex);
        vm.stopBroadcast();
    }
}