// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {BitarenaChallenge} from "../../../src/BitarenaChallenge.sol";

contract CalculateAmountPerPlayer is Script {
    function run(address challengeAddress) public view {
        BitarenaChallenge challenge = BitarenaChallenge(payable(challengeAddress));
        
        // Récupérer l'équipe gagnante
        uint16 winnerTeamIndex = challenge.getWinnerTeam();
        console2.log("Index team gagnante:", winnerTeamIndex);

        // Récupérer les joueurs de l'équipe gagnante
        address[] memory winningTeam = challenge.getTeamsByTeamIndex(winnerTeamIndex);
        uint256 playerWinnersCount = winningTeam.length;
        console2.log("Nombre de joueurs dans la team gagnante:", playerWinnersCount);

        // Récupérer le montant total à distribuer
        uint256 totalPoolAmountForWinner = challenge.calculatePoolAmountToSendBackForWinnerTeam();
        console2.log("Montant total a distribuer (en wei):", totalPoolAmountForWinner);
        console2.log("Montant total a distribuer (en ETH):", totalPoolAmountForWinner / 1e18);

        if (playerWinnersCount == 0) {
            console2.log("ERREUR: Division par zero car playerWinnersCount = 0");
            return;
        }

        // Calculer le montant par joueur
        uint256 amountPerPlayer = totalPoolAmountForWinner / playerWinnersCount;
        console2.log("Montant par joueur (en wei):", amountPerPlayer);
        console2.log("Montant par joueur (en ETH):", amountPerPlayer / 1e18);

        // Vérifier si la division est exacte
        if (totalPoolAmountForWinner % playerWinnersCount != 0) {
            console2.log("ATTENTION: La division n'est pas exacte!");
            console2.log("Reste de la division:", totalPoolAmountForWinner % playerWinnersCount);
        }

        // Vérifier le total
        console2.log("VErification: montant total reconstruit:", amountPerPlayer * playerWinnersCount);
        console2.log("DiffErence avec le montant initial:", totalPoolAmountForWinner - (amountPerPlayer * playerWinnersCount));
    }
}