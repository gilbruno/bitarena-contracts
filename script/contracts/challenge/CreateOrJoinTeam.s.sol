// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {BitarenaChallenge} from "../../../src/BitarenaChallenge.sol";

contract CreateOrJoinTeam is Script {
    function run(address challengeAddress, uint16 teamIndex) external {

        // Récupération du montant requis depuis le contrat
        BitarenaChallenge challenge = BitarenaChallenge(payable(challengeAddress));
        uint256 amountRequired = challenge.getAmountPerPlayer();

        uint256 playerPrivateKey = vm.envUint("PRIVATE_KEY_PLAYER_1");
        vm.startBroadcast(playerPrivateKey);
        BitarenaChallenge(payable(challengeAddress)).createOrJoinTeam{value: amountRequired}(teamIndex);
        vm.stopBroadcast();
    }
}