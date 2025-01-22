// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {ChallengeParams} from "./ChallengeParams.sol";

interface IBitarenaChallengesData {
    /**
     * @dev Événement émis lorsqu'un nouveau challenge est ajouté pour un joueur
     */
    event ChallengeAddedToHistory(address indexed player, ChallengeParams challenge);

    // Événement émis lorsqu'un nouveau contrat Challenge est autorisé
    event ChallengeContractAuthorized(address indexed challengeContract);

    // Event émis quand un nouveau challenge est enregistré
    event ChallengeContractRegistered(address indexed challengeContract);

    error InvalidChallengeAddress();
    error ChallengeAlreadyRegistered();
    error NotOfficialChallenge();
    error AddressZeroError();

    function authorizeConractsRegistering(address _factoryAddress) external;

    /**
     * @dev Ajoute un challenge à l'historique d'un joueur
     * @param _player L'adresse du joueur
     * @param _challenge Les paramètres du challenge
     */
    function addChallengeToPlayerHistory(address _player, ChallengeParams memory _challenge) external;

    function registerChallengeContract(address _challengeContract) external;
    /**
     * @dev Récupère tous les challenges d'un joueur
     * @param _player L'adresse du joueur
     * @return Un tableau de ChallengeParams
     */
    function getPlayerChallenges(address _player) external view returns (ChallengeParams[] memory);

    /**
     * @dev Récupère le nombre de challenges d'un joueur
     * @param _player L'adresse du joueur
     * @return Le nombre de challenges
     */
    function getPlayerChallengesCount(address _player) external view returns (uint256);
}