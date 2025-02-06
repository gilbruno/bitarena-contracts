// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {BitarenaChallenge} from "../../../src/BitarenaChallenge.sol";

contract SetDelayVictoryClaim is Script {
    function run(
        address challengeAddress,
        bool isStartDelay,  // true pour start delay, false pour end delay
        uint256 delay
    ) public {
        uint256 adminChallengePrivateKey = vm.envUint("PRIVATE_KEY_ADMIN_CHALLENGE");
        
        vm.startBroadcast(adminChallengePrivateKey);

        BitarenaChallenge challenge = BitarenaChallenge(payable(challengeAddress));

        if (isStartDelay) {
            challenge.setDelayStartForVictoryClaim(delay);
        } else {
            challenge.setDelayEndForVictoryClaim(delay);
        }

        vm.stopBroadcast();
    }
}