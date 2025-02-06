// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {BitarenaChallenge} from "../../../src/BitarenaChallenge.sol";

contract WithdrawChallengePool is Script {
    function run(address challengeAddress) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_PLAYER_1");
        
        vm.startBroadcast(deployerPrivateKey);
        BitarenaChallenge challenge = BitarenaChallenge(payable(challengeAddress));
        challenge.withdrawChallengePool();
        vm.stopBroadcast();
    }
}