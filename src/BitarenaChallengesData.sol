// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import {ChallengeParams} from "./struct/ChallengeParams.sol";
import {IBitarenaChallengesData} from "./interfaces/IBitarenaChallengesData.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {AccessControlUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {BitarenaChallenge} from "./BitarenaChallenge.sol";
import {ChallengeData} from "./struct/ChallengeData.sol";
import {IBitarenaUpgrade} from "./interfaces/IBitarenaUpgrade.sol";
import {ERC1967Utils} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract BitarenaChallengesData is AccessControlUpgradeable, IBitarenaChallengesData, IBitarenaUpgrade, UUPSUpgradeable {
    /**
     * @dev Role for the authorized BitarenaChallenge contracts
     */
    bytes32 public constant CHALLENGE_DATA_ADMIN_ROLE = keccak256("CHALLENGE_DATA_ADMIN_ROLE");

    /**
     * @dev Role for the official factory
     */
    bytes32 public constant CONTRACTS_REGISTERING_ROLE = keccak256("CONTRACTS_REGISTERING_ROLE");

    /**
     * @dev Role for the upgrade admin
     */
    bytes32 public constant UPGRADE_ADMIN_ROLE = keccak256("UPGRADE_ADMIN_ROLE");

    /**
     * @dev Mapping from a wallet to an array of ChallengeParams
     */
    mapping(address => ChallengeParams[]) private s_playerChallenges;
    
    /**
     * @dev Mapping of challenges
     */
    mapping(address => ChallengeData) private s_challenges;

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
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _superAdmin);
    }

    /**
     * @dev Authorize an addresse to register challenges. 
     * Normally it' the BitarenaFactory it can be any other address in some specific cases
     */
    function authorizeConractsRegistering(address _factoryAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CONTRACTS_REGISTERING_ROLE, _factoryAddress);
    }

    function _buildChallenge(address payable deployedChallengeAddress) internal view returns (ChallengeData memory) {

        address challengeCreator = BitarenaChallenge(deployedChallengeAddress).getCreator();
        address challengeAdmin = BitarenaChallenge(deployedChallengeAddress).getChallengeAdmin();
        address challengeDisputeAdmin = BitarenaChallenge(deployedChallengeAddress).getDisputeAdmin();
        string memory game = BitarenaChallenge(deployedChallengeAddress).getGame();
        string memory platform = BitarenaChallenge(deployedChallengeAddress).getPlatform();
        uint16 nbTeams = BitarenaChallenge(deployedChallengeAddress).getNbTeams();
        uint16 nbTeamPlayers = BitarenaChallenge(deployedChallengeAddress).getNbTeamPlayers();
        uint256 amountPerPlayer = BitarenaChallenge(deployedChallengeAddress).getAmountPerPlayer();
        uint256 startAt = BitarenaChallenge(deployedChallengeAddress).getChallengeStartDate();
        bool isPrivate = BitarenaChallenge(deployedChallengeAddress).getChallengeVisibility();
        uint256 delayStartVictoryClaim = BitarenaChallenge(deployedChallengeAddress).getDelayStartVictoryClaim();
        uint256 delayEndVictoryClaim = BitarenaChallenge(deployedChallengeAddress).getDelayEndVictoryClaim();
        uint256 delayStartDisputeParticipation = BitarenaChallenge(deployedChallengeAddress).getDelayStartDisputeParticipation();
        uint256 delayEndDisputeParticipation = BitarenaChallenge(deployedChallengeAddress).getDelayEndDisputeParticipation();
        uint256 feePercentageDispute = BitarenaChallenge(deployedChallengeAddress).getFeePercentageDispute();

        ChallengeData memory newChallenge = ChallengeData({
            challengeAddress: deployedChallengeAddress,
            challengeCreator: challengeCreator,
            challengeAdmin: challengeAdmin,
            challengeDisputeAdmin: challengeDisputeAdmin,
            game: game,
            platform: platform,
            nbTeams: nbTeams,
            nbTeamPlayers: nbTeamPlayers,
            amountPerPlayer: amountPerPlayer,
            startAt: startAt,
            isPrivate: isPrivate,
            pool: 0,                      
            winnerTeam: 0,
            winnersClaimedCount: 0,
            delayStartVictoryClaim: delayStartVictoryClaim,
            delayEndVictoryClaim: delayEndVictoryClaim,
            delayStartDisputeParticipation: delayStartDisputeParticipation,
            delayEndDisputeParticipation: delayEndDisputeParticipation,
            feePercentageDispute: feePercentageDispute
        });
        return newChallenge;
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
        
        ChallengeData memory challenge = _buildChallenge(payable(_challengeContract));
        s_challenges[_challengeContract] = challenge;
        emit ChallengeContractRegistered(_challengeContract, challenge);
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
     * @dev Update the winners claimed count for a challenge
     * @param _challengeContract Address of the challenge contract
     */
    function updateWinnersClaimedCount(address _challengeContract) external onlyOfficialChallenge {
        if(_challengeContract == address(0)) revert InvalidChallengeAddress();
        
        ChallengeData storage challenge = s_challenges[_challengeContract];
        unchecked {
            challenge.winnersClaimedCount++;
        }
        emit WinnersClaimedCountUpdated(_challengeContract, challenge.winnersClaimedCount);
    }

    function updateChallengePool(address _challengeContract, uint256 _amountToAdd) external onlyOfficialChallenge {
        if(_challengeContract == address(0)) revert InvalidChallengeAddress();
        
        ChallengeData storage challenge = s_challenges[_challengeContract];
        uint256 newPoolAmount;
        unchecked {
            newPoolAmount = challenge.pool + _amountToAdd;
        }
        challenge.pool = newPoolAmount;
        
        emit ChallengePoolUpdated(_challengeContract, newPoolAmount);
    }

    /**
     * @dev Update the winner team for a challenge. If a winner was already set, reset it to 0 (dispute case)
     * @param _challengeContract Address of the challenge contract
     * @param _teamIndex Index of the winning team
     */
    function updateWinnerTeam(address _challengeContract, uint16 _teamIndex) external onlyOfficialChallenge {
        if(_challengeContract == address(0)) revert InvalidChallengeAddress();
        
        ChallengeData storage challenge = s_challenges[_challengeContract];
        
        if (challenge.winnerTeam != 0) {
            // A team has already claimed the victory, we reset it to 0 (dispute case)
            challenge.winnerTeam = 0;
        } else {
            // First team to claim the victory
            challenge.winnerTeam = _teamIndex;
        }
        
        emit WinnerTeamUpdated(_challengeContract, challenge.winnerTeam);
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
     * @param _challengeAddress Address of the challenge
     * @param _challenge The challenge parameters
     */
    function addChallengeToPlayerHistory(address _player, address _challengeAddress, ChallengeParams memory _challenge, uint16 _teamIndex) public onlyOfficialChallenge() {
        if(_player == address(0)) revert AddressZeroError();
        // Get the existing array
        //ChallengeParams[] storage playerChallenges = s_playerChallenges[_player];
        
        // Update the mapping with the modified array
        s_playerChallenges[_player].push(_challenge);
        
        emit ChallengeAddedToPlayerHistory(_player, _challengeAddress, _teamIndex);  
        
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
     * @dev Get the challenge parameters for a specific challenge address
     * @param _challengeContract Address of the challenge contract
     * @return ChallengeParams The challenge parameters
     */
    function getChallengeData(address _challengeContract) external view returns (ChallengeData memory) {
        return s_challenges[_challengeContract];
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

    /**
     * @dev Authorize the upgrade of the contract
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override view {
        if (!hasRole(UPGRADE_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedUpgrade(msg.sender);
        }
         if (newImplementation == address(0)) {
            revert UnauthorizedNewImplementationWithNullAddress();
        }
    }

    /**
     * @dev Upgrade the contract to a new implementation
     * @param newImplementation Address of the new implementation
     * @param data Data to pass to the new implementation
     */
    function upgradeToAndCallSecure(address newImplementation, bytes memory data) external payable onlyRole(UPGRADE_ADMIN_ROLE) {
        upgradeToAndCall(newImplementation, data);
    }

    function getImplementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    function proxiableUUID() external view override notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

}