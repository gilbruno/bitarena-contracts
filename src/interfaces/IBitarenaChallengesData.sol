// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {ChallengeParams} from "../struct/ChallengeParams.sol";
import {Challenge} from "../struct/Challenge.sol";
interface IBitarenaChallengesData {
    /**
     * @dev Événement émis lorsqu'un nouveau challenge est ajouté pour un joueur
     */
    event ChallengeAddedToPlayerHistory(address indexed player, address challengeAddress);

    // Événement émis lorsqu'un nouveau contrat Challenge est autorisé
    event ChallengeContractAuthorized(address indexed challengeContract);

    // Event émis quand un nouveau challenge est enregistré
    event ChallengeContractRegistered(address indexed challengeContract, Challenge challengeParams);

    event ChallengeStarted(address indexed challengeContract);
    event ChallengeEnded(address indexed challengeContract);
    event ChallengeVictoryClaimed();
    event WinnersClaimedCountUpdated(address indexed challengeContract, uint256 newWinnersCount);
    event ChallengePoolUpdated(address challengeAddress, uint256 newPoolAmount);
    event WinnerTeamUpdated(address challengeAddress, uint16 winnerTeamIndex);

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
     * @param _challengeAddress L'adresse du challenge
     * @param _challenge Les paramètres du challenge
     */
    function addChallengeToPlayerHistory(address _player, address _challengeAddress, ChallengeParams memory _challenge) external;

    function registerChallengeContract(address _challengeContract) external;

    function updateWinnersClaimedCount(address _challengeContract) external;
    
    function updateChallengePool(address _challengeContract, uint256 _amountToAdd) external;
    
    function updateWinnerTeam(address _challengeContract, uint16 _teamIndex) external;
    
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
