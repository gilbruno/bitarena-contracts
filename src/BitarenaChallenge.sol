// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {AccessControlDefaultAdminRules} from "openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {BalanceChallengePlayerError, ChallengeCancelAfterStartDateError, NbTeamsLimitReachedError, NbPlayersPerTeamsLimitReachedError, TeamDoesNotExistsError, TimeElapsedToCreateDisputeError, TimeElapsedToJoinTeamError} from "./BitarenaChallengeErrors.sol";
import {PlayerJoinsTeam, TeamCreated, Debug} from "./BitarenaChallengeEvents.sol";
import {ChallengeParams} from "./ChallengeParams.sol";

contract BitarenaChallenge is Context, AccessControlDefaultAdminRules{

    bytes32 private s_name;
    bytes32 private s_game;
    bytes32 private s_platform;
    uint16 private immutable s_nbTeams;
    uint16 private immutable s_nbTeamPlayers;
    uint16 private s_percentageAmountDispute;
    uint256 private immutable s_startAt;
    uint256 private immutable s_amountPerPlayer;
    uint256 private s_delayVictoryClaim;
    uint256 private s_challengePool;

    uint16 private s_teamCounter;
    bool private s_isPrivate;
    bool private s_isCanceled;
    address private s_admin;
    address private s_litigationAdmin;
    address private immutable s_creator;
    address private immutable s_factory;

    mapping(uint16 teamIndex => address[] players) private s_players;
    mapping(uint16 teamIndex => bool winner) s_winners;

    /** CONSTANTS */
    bytes32 public constant CHALLENGE_ADMIN_ROLE = keccak256("CHALLENGE_ADMIN_ROLE");
    bytes32 public constant CHALLENGE_LITIGATION_ADMIN_ROLE = keccak256("CHALLENGE_LITIGATION_ADMIN_ROLE");
    bytes32 public constant CHALLENGE_CREATOR_ROLE = keccak256("CHALLENGE_CREATOR_ROLE");
    bytes32 public constant GAMER_ROLE = keccak256("GAMER_ROLE");
    uint8 private constant DECIMALS_PERCENTAGE_AMOUNT_DISPUTE = 2;

    constructor(ChallengeParams memory params) AccessControlDefaultAdminRules(1 days, params.challengeAdmin) {
        s_factory = params.factory;
        s_admin = params.challengeAdmin;
        s_litigationAdmin = params.challengeDisputeAdmin;
        s_creator = params.challengeCreator;
        s_name = params.name;
        s_game = params.game;
        s_platform = params.platform;
        s_nbTeams = params.nbTeams;
        s_nbTeamPlayers = params.nbTeamPlayers;
        s_amountPerPlayer = params.amountPerPlayer;
        s_startAt = params.startAt;
        s_isPrivate = params.isPrivate;
        s_isCanceled = false;
        s_teamCounter = 0;
        s_challengePool = 0;
        _grantRole(CHALLENGE_ADMIN_ROLE, params.challengeAdmin);
        _grantRole(CHALLENGE_CREATOR_ROLE, params.challengeCreator);

    }


    function createTeam() internal {
        if (s_teamCounter == s_nbTeams) revert NbTeamsLimitReachedError();
        unchecked {
            ++s_teamCounter;
        }
        
        //If a team is created for the first time, we add the creator in this team.
        // Otherwise we add the creator of the team in the created team
        address player = s_teamCounter == 1 ? s_creator : _msgSender();
        s_players[s_teamCounter].push(player);
        s_winners[s_teamCounter] = false;
        emit PlayerJoinsTeam(s_teamCounter, player);
        emit TeamCreated(s_teamCounter);
    }

    function joinTeam(uint16 _teamIndex) internal {
        if (s_players[_teamIndex].length == s_nbTeamPlayers) revert NbPlayersPerTeamsLimitReachedError();
        if (_teamIndex > s_teamCounter) revert TeamDoesNotExistsError();
        s_players[_teamIndex].push(_msgSender());
        emit PlayerJoinsTeam(_teamIndex, _msgSender());
    }

    /**
     * @dev Function that will be callable by front end. 
     * If value of _teamIndex equals 0 then it's a creation team intent
     * Oherwise the player wants to join the team with specified index
     * When you join a team you must pay the 'amountPerPlayer'. 
     * We have an exception when the factory call the function because that's the first team creation by the challenge creator 
     * and he already paid for the challenge.
     * We reject the Tx if a player wants to join a team afetr the challenge start date
     * @param _teamIndex : index of the team
     */
    function joinOrCreateTeam(uint16 _teamIndex) public payable {
        if (msg.value < s_amountPerPlayer && _msgSender() != s_factory) revert BalanceChallengePlayerError();
        //Intent to create a new team (and becomes automatically a member of the newly created team)
        if (_teamIndex == 0) {
            createTeam();
        }
        else {
            if (block.timestamp >= s_startAt) revert TimeElapsedToJoinTeamError();
            joinTeam(_teamIndex);
            _grantRole(GAMER_ROLE, _msgSender());
        }
        incrementChallengePool(s_amountPerPlayer);
    }
    

    /**
     * @dev
     * @param _teamIndex : indexof the team
     */
    function claimVictory(uint16 _teamIndex) public onlyRole(GAMER_ROLE) onlyRole(CHALLENGE_CREATOR_ROLE){
        s_winners[_teamIndex] = true;
    }

    /**
     * @dev
     */
    function setPercentageForDispute() public onlyRole(CHALLENGE_ADMIN_ROLE) {

    }

    /** All players can create a dispute.
     * Only one player create a dispute for his team.
     * So before the delay set by the admin, it's possible to create a dispute. 
     * After the delay, it's not possible to create a dispute
     
     * @dev 
     */
    function createDispute() public onlyRole(GAMER_ROLE) onlyRole(CHALLENGE_CREATOR_ROLE) {
        if (block.timestamp >= s_startAt + s_delayVictoryClaim) revert TimeElapsedToCreateDisputeError();
    }

    /**
     * Delay set by the admin during which you can create a dispute to challenge the victory.
     * It runs after the challenge start date.
     * @dev
     */
    function setDelayForVictoryClaim(uint256 _delayForVictoryClaim) public onlyRole(CHALLENGE_ADMIN_ROLE) {
        s_delayVictoryClaim = _delayForVictoryClaim;
    }


    /**
     * @dev 
     */
    receive() external payable {
        
    }

    /**
     * @dev 
     */
    fallback() external payable {
        
    }
    
    /**
     * @dev increment the challenge pool
     */
    function incrementChallengePool(uint256 _amount) internal {
        s_challengePool += _amount;
    }

    /**
     * @dev Only the challengecreator can cancel  a challenge only before _startDate
     */
    function cancelChallenge() public onlyRole(CHALLENGE_CREATOR_ROLE) {
        if (block.timestamp > s_startAt) revert ChallengeCancelAfterStartDateError();
        setIsCanceled(true);
    }

    /**
     * @dev getter for state variable s_name
     */
    function getName() external view returns (bytes32) {
        return s_name;
    }

    /**
     * @dev getter for state variable s_creator
     */
    function getCreator() external view returns (address) {
        return s_creator;
    }

    /**
     * @dev getter for state variable s_game
     */
    function getGame() external view returns (bytes32) {
        return s_game;
    }

    /**
     * @dev getter for state variable s_platform
     */
    function getPlatform() external view returns (bytes32) {
        return s_platform;
    }
    /**
     * @dev getter for state variable s_nbTeams
     */
    function getNbTeams() external view returns (uint16) {
        return s_nbTeams;
    }

    /**
     * @dev getter for state variable s_nbTeamPlayers
     */
    function getNbTeamPlayers() external view returns (uint16) {
        return s_nbTeamPlayers;
    }

    /**
     * @dev getter for state variable s_startAt
     */
    function getChallengeStartDate() external view returns (uint256) {
        return s_startAt;
    }

    /**
     * @dev getter for state variable s_isPrivate
     */
    function getChallengeVisibility() external view returns (bool) {
        return s_isPrivate;
    }

    /**
     * @dev getter for state variable s_isCanceled
     */
    function getIsCanceled() external view returns (bool) {
        return s_isCanceled;
    }

    /**
     * @dev setter for state variable s_isCanceled
     */
    function setIsCanceled(bool _isCanceled) internal {
        s_isCanceled = _isCanceled;
    }

    /**
     * @dev getter for state variable s_amountPerPlayer
     */
    function getAmountPerPlayer() external view returns (uint256) {
        return s_amountPerPlayer;
    }


    /**
     * @dev getter for the state variable s_teamCounter
     */
    function getTeamCounter() external view returns (uint16) {
        return s_teamCounter;
    }

    /**
     * @dev getter for mapping state variable s_players
     */
    function getPlayersByTeamIndex(uint16 _teamIndex) external view returns (address[] memory) {
        return s_players[_teamIndex];
    }

    /**
     * @dev getter for state variable s_delayVictoryClaim
     */
    function getDelayVictoryClaim() external view returns (uint256) {
        return s_delayVictoryClaim;
    }

    /**
     * @dev getter for state variable s_percentageAmountDispute
     */
    function getPercentageAmountdispute() external view returns (uint16) {
        return s_percentageAmountDispute;
    }

    /**
     * @dev getter for state variable s_challengePool
     */
    function getChallengePool() external view returns (uint256) {
        return s_challengePool;
    }

}