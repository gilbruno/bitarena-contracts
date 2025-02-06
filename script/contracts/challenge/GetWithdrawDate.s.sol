// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {BitarenaChallenge} from "../../../src/BitarenaChallenge.sol";

contract GetWithdrawDate is Script {
    function run(address challengeAddress) public view {
        
        BitarenaChallenge challenge = BitarenaChallenge(payable(challengeAddress));
        
        uint256 startAt = challenge.getChallengeStartDate();
        uint256 delayStartVictory = challenge.getDelayStartVictoryClaim();
        uint256 delayEndVictory = challenge.getDelayEndVictoryClaim();
        uint256 delayStartDispute = challenge.getDelayStartDisputeParticipation();
        uint256 delayEndDispute = challenge.getDelayEndDisputeParticipation();

        uint256 withdrawDate = startAt + delayStartVictory + delayEndVictory + delayStartDispute + delayEndDispute;
        uint256 currentTimestamp = block.timestamp;

        console2.log("Date de debut du challenge :", startAt);
        console2.log("Delay avant reclamation victoire :", delayStartVictory);
        console2.log("Duree periode de reclamation victoire :", delayEndVictory);
        console2.log("Delay avant participation dispute :", delayStartDispute);
        console2.log("Duree periode de dispute :", delayEndDispute);
        console2.log("-----------------------------------------");
        console2.log("Date possible de withdraw (timestamp):", withdrawDate);   
        console2.log("Date actuelle (timestamp) :", currentTimestamp);
        
        if (currentTimestamp < withdrawDate) {
            console2.log("Temps restant avant withdraw possible (en secondes):", withdrawDate - currentTimestamp);
            console2.log("Temps restant avant withdraw possible (en heures):", (withdrawDate - currentTimestamp) / 3600);
        } else {
            console2.log("Le withdraw est deja possible !");
        }
    }
}