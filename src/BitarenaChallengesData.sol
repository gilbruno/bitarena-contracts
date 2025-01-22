// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {ChallengeParams} from "./ChallengeParams.sol";
import {IBitarenaChallengesData} from "./IBitarenaChallengesData.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {AccessControlUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

contract BitarenaChallengesData is AccessControlUpgradeable, IBitarenaChallengesData {
    /**
     * @dev Role for the authorized BitarenaChallenge contracts
     */
    bytes32 public constant CHALLENGE_DATA_ADMIN_ROLE = keccak256("CHALLENGE_DATA_ADMIN_ROLE");

    /**
     * @dev Role for the official factory
     */
    bytes32 public constant CONTRACTS_REGISTERING_ROLE = keccak256("CONTRACTS_REGISTERING_ROLE");

    /**
     * @dev Mapping from a wallet to an array of ChallengeParams
     */
    mapping(address => ChallengeParams[]) private s_playerChallenges;
    
    /**
     * @dev Mapping to track the challenges created by the factory
     */
    mapping(address => bool) private s_isOfficialChallenge;

    /**
     * @dev Mapping to track if a challenge is started
     */
    mapping(address => bool) private s_isChallengeStarted;
    
    /**
     * @dev Mapping to track if a challenge is ended
     */
    mapping(address => bool) private s_isChallengeEnded;

    // Mapping pour les challenges officiels avec leur ID
    mapping(address => uint256) private s_challengeIds;
    
    // Mapping inverse pour retrouver l'adresse par ID
    mapping(uint256 => address) private s_challengeAddresses;
    
    // Compteur de challenges
    uint256 private s_challengeCounter;


    /**
     * @dev Reserve some slots for future upgrades
     */
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

    /**
     * @dev Initialize the contract
     * @param _superAdmin Address of the super admin
     */
    function initialize(address _superAdmin) initializer public {
        if(_superAdmin == address(0)) revert AddressZeroError();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _superAdmin);
    }

    /**
     * @dev Authorize an addresse to register challenges. 
     * Normally it' the BitarenaFactory it can be any other address in some specific cases
     */
    function authorizeConractsRegistering(address _factoryAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CONTRACTS_REGISTERING_ROLE, _factoryAddress);
    }

    /**
     * @dev Register a new challenge contract as official
     * @param _challengeContract Address of the challenge contract to register
     * @notice Only the authorized factory can call this function
     */
    function registerChallengeContract(address _challengeContract) public onlyRole(CONTRACTS_REGISTERING_ROLE) 
    {
        if(_challengeContract == address(0)) revert InvalidChallengeAddress();
        if(s_isOfficialChallenge[_challengeContract]) revert ChallengeAlreadyRegistered();
        
        // Increment the counter and register the challenge
        unchecked { s_challengeCounter++; }
        uint256 challengeId = s_challengeCounter;
        
        s_challengeIds[_challengeContract] = challengeId;
        s_challengeAddresses[challengeId] = _challengeContract;
        s_isOfficialChallenge[_challengeContract] = true;
        
        emit ChallengeContractRegistered(_challengeContract);
    }

    /**
     * @dev Get a batch of challenges
     * @param _start Start index
     * @param _size Batch size
     */
    function getChallengesBatch(uint256 _start, uint256 _size) external view returns (address[] memory challenges) 
    {
        if(_size > 100) revert BatchTooLarge();
        if(_start + _size > s_challengeCounter && _size <= 100) revert InvalidBatch();
        

        challenges = new address[](_size);
        for(uint256 i = 0; i < _size; i++) {
            challenges[i] = s_challengeAddresses[_start + i + 1];
        }
        return challenges;
    }

     /**
     * @dev Récupère le nombre total de challenges
     */
    function getTotalChallenges() external view returns (uint256) {
        return s_challengeCounter;
    }

     /**
     * @dev Récupère l'ID d'un challenge
     */
    function getChallengeId(address _challenge) external view returns (uint256) {
        return s_challengeIds[_challenge];
    }

    /**
     * @dev Récupère l'adresse d'un challenge par son ID
     */
    function getChallengeAddress(uint256 _id) external view returns (address) {
        if(_id == 0 ||_id > s_challengeCounter) revert InvalidId();
        return s_challengeAddresses[_id];
    }


    /**
     * @dev Check if a challenge contract is official
     * @param _challengeContract Address of the contract to check
     * @return bool true if the challenge is official, false otherwise
     */
    function isOfficialChallenge(address _challengeContract) external view returns (bool) {
        return s_isOfficialChallenge[_challengeContract];
    }


    /**
     * @dev Authorize a new BitarenaChallenge contract
     * @param _challengeDataAdmin Address to authorize
     */
    function grantRoleChallangeDataAdmin(address _challengeDataAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CHALLENGE_DATA_ADMIN_ROLE, _challengeDataAdmin);
        emit ChallengeContractAuthorized(_challengeDataAdmin);
    }

    /**
     * @dev Add a challenge to a player's history
     * @param _player Address of the player
     * @param _challenge The challenge parameters
     */
    function addChallengeToPlayerHistory(address _player, ChallengeParams memory _challenge) public onlyOfficialChallenge() {
        if(_player == address(0)) revert AddressZeroError();
        // Récupérer le tableau existant
        //ChallengeParams[] storage playerChallenges = s_playerChallenges[_player];
        //emit Debug("Taille du tableau ", playerChallenges.length);

        // Ajouter le nouveau challenge
        //s_playerChallenges[_player].push(_challenge);
        
        // Mettre à jour le mapping avec le tableau modifié
        s_playerChallenges[_player].push(_challenge);
        
        emit ChallengeAddedToHistory(_player, _challenge);
        
        // Debug log
        emit Debug("Taille du tableau apres ajout", s_playerChallenges[_player].length);
        emit Debug2("Address ChallengesData", address(this));
    }

/**
     * @dev Mark a challenge as started
     * @param _challengeContract Address of the challenge
     */
    function setChallengeAsStarted(address _challengeContract) external onlyOfficialChallenge() {
        if(_challengeContract == address(0)) revert InvalidChallengeAddress();
        if(s_isChallengeStarted[_challengeContract]) revert ChallengeAlreadyStarted();
        
        s_isChallengeStarted[_challengeContract] = true;
        
        emit ChallengeStarted(_challengeContract);
    }

    /**
     * @dev Mark a challenge as ended
     * @param _challengeContract Address of the challenge
     */
    function setChallengeAsEnded(address _challengeContract) external onlyOfficialChallenge() {
        if(_challengeContract == address(0)) revert InvalidChallengeAddress();
        //if(!s_isChallengeStarted[_challengeContract]) revert ChallengeNotStarted();
        if(s_isChallengeEnded[_challengeContract]) revert ChallengeAlreadyEnded();
        
        s_isChallengeEnded[_challengeContract] = true;
        
        emit ChallengeEnded(_challengeContract);
    }

    /**
     * @dev Check if a challenge is started
     * @param _challengeContract Address of the challenge
     * @return bool true if the challenge is started, false otherwise
     */
    function isChallengeStarted(address _challengeContract) external view returns (bool) {
        return s_isChallengeStarted[_challengeContract];
    }

    /**
     * @dev Check if a challenge is ended
     * @param _challengeContract Address of the challenge
     * @return bool true if the challenge is ended, false otherwise
     */
    function isChallengeEnded(address _challengeContract) external view returns (bool) {
        return s_isChallengeEnded[_challengeContract];
    }

    /**
     * @dev Get all challenges of a player
     * @param _player Address of the player
     * @return An array of ChallengeParams
     */
    function getPlayerChallenges(address _player) external view returns (ChallengeParams[] memory) {
        return s_playerChallenges[_player];
    }

    /**
     * @dev Get the number of challenges of a player
     * @param _player Address of the player
     * @return The number of challenges
     */
    function getPlayerChallengesCount(address _player) external view returns (uint256) {
        return s_playerChallenges[_player].length;
    }
}