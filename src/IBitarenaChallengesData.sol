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

    event ChallengeStarted(address indexed challengeContract);
    event ChallengeEnded(address indexed challengeContract);
    event Debug(string message, uint256 value);
    event Debug2(string message, address value);

    error InvalidChallengeAddress();
    error ChallengeAlreadyRegistered();
    error NotOfficialChallenge();
    error AddressZeroError();
    error ChallengeAlreadyStarted();
    error ChallengeAlreadyEnded();
    error ChallengeNotStarted();
    error InvalidBatch();
    error BatchTooLarge();
    error InvalidId();

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

    function getChallengesBatch(uint256 _start, uint256 _size) external view returns (address[] memory);
    function getTotalChallenges() external view returns (uint256);
    function getChallengeId(address _challenge) external view returns (uint256);
    function getChallengeAddress(uint256 _id) external view returns (address);

    function isChallengeStarted(address _challengeContract) external view returns (bool);
    function isChallengeEnded(address _challengeContract) external view returns (bool);

    function setChallengeAsStarted(address _challengeContract) external;
    function setChallengeAsEnded(address _challengeContract) external;
}
