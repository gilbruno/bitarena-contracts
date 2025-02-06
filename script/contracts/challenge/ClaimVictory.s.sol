// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {BitarenaChallenge} from "../../../src/BitarenaChallenge.sol";

contract ClaimVictory is Script {
    
    function run(address challengeAddress) public {
        // Récupération de la clé privée depuis les variables d'environnement
        uint256 playerPrivateKey = vm.envUint("PRIVATE_KEY_PLAYER_1");
        
        // Début de la transaction
        vm.startBroadcast(playerPrivateKey);
        // Création d'une instance du contrat
        BitarenaChallenge bitarenaChallenge = BitarenaChallenge(payable(challengeAddress));
        // Appel de la fonction claimVictory
        bitarenaChallenge.claimVictory();
        vm.stopBroadcast();
    }
}