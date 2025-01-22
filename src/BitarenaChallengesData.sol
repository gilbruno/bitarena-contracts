// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {ChallengeParams} from "./ChallengeParams.sol";
import {IBitarenaChallengesData} from "./IBitarenaChallengesData.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {AccessControlUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

contract BitarenaChallengesData is AccessControlUpgradeable, IBitarenaChallengesData {
     // Role pour les contrats BitarenaChallenge autorisés
    bytes32 public constant CHALLENGE_DATA_ADMIN_ROLE = keccak256("CHALLENGE_DATA_ADMIN_ROLE");

    // Role pour la factory officielle
    bytes32 public constant CONTRACTS_REGISTERING_ROLE = keccak256("CONTRACTS_REGISTERING_ROLE");

    // Mapping d'un wallet vers un tableau de ChallengeParams
    mapping(address => ChallengeParams[]) private s_playerChallenges;
    
    // Mapping pour tracker les challenges créés par la factory
    mapping(address => bool) private s_isOfficialChallenge;

    // Reserve some slots for future upgrades
    uint256[50] private __gap; 

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

        /**
     * @dev Modifier to check if the caller is an admin or super admin
     */
    modifier onlyAdminOrSuperAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) 
                || hasRole(CHALLENGE_DATA_ADMIN_ROLE, _msgSender())
            , "Caller must be authorized entities"
            );
        _;
    }
    /**
     * @dev Modifier to check if the caller is an official challenge
     */
    modifier onlyOfficialChallenge() {
        if (!s_isOfficialChallenge[_msgSender()]) revert NotOfficialChallenge();
        _;
    }


    function initialize(address _superAdmin) initializer public {
        if(_superAdmin == address(0)) revert AddressZeroError();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _superAdmin);
    }

    /**
     * @dev Authorize an addresse to register challenges. Normally it' the BitarenaFactory ut can be any other address in some specific cases
     */
    function authorizeConractsRegistering(address _factoryAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CONTRACTS_REGISTERING_ROLE, _factoryAddress);
    }

    /**
     * @dev Enregistre un nouveau contrat Challenge comme étant officiel
     * @param _challengeContract L'adresse du contrat BitarenaChallenge à enregistrer
     * @notice Seule la factory autorisée peut appeler cette fonction
     */
    function registerChallengeContract(address _challengeContract) public onlyRole(CONTRACTS_REGISTERING_ROLE) 
    {
        if(_challengeContract == address(0)) revert InvalidChallengeAddress();
        if(s_isOfficialChallenge[_challengeContract]) revert ChallengeAlreadyRegistered();
        
        s_isOfficialChallenge[_challengeContract] = true;
        
        emit ChallengeContractRegistered(_challengeContract);
    }

    /**
     * @dev Vérifie si un contrat Challenge est officiel
     * @param _challengeContract L'adresse du contrat à vérifier
     * @return bool true si le challenge est officiel, false sinon
     */
    function isOfficialChallenge(address _challengeContract) external view returns (bool) {
        return s_isOfficialChallenge[_challengeContract];
    }


    /**
     * @dev Permet à l'admin d'autoriser un nouveau contrat BitarenaChallenge
     * @param _challengeDataAdmin L'adresse à autoriser
     */
    function grantRoleChallangeDataAdmin(address _challengeDataAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CHALLENGE_DATA_ADMIN_ROLE, _challengeDataAdmin);
        emit ChallengeContractAuthorized(_challengeDataAdmin);
    }

    /**
     * @dev Ajoute un challenge à l'historique d'un joueur
     * @param _player L'adresse du joueur
     * @param _challenge Les paramètres du challenge
     */
    function addChallengeToPlayerHistory(address _player, ChallengeParams memory _challenge) public onlyOfficialChallenge() {
        s_playerChallenges[_player].push(_challenge);
        emit ChallengeAddedToHistory(_player, _challenge);
    }

    /**
     * @dev Récupère tous les challenges d'un joueur
     * @param _player L'adresse du joueur
     * @return Un tableau de ChallengeParams
     */
    function getPlayerChallenges(address _player) external view returns (ChallengeParams[] memory) {
        return s_playerChallenges[_player];
    }

    /**
     * @dev Récupère le nombre de challenges d'un joueur
     * @param _player L'adresse du joueur
     * @return Le nombre de challenges
     */
    function getPlayerChallengesCount(address _player) external view returns (uint256) {
        return s_playerChallenges[_player].length;
    }
}