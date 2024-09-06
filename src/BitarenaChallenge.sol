// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {AccessControlDefaultAdminRules} from "openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {ChallengeCancelAfterStartDateError, NbTeamsLimitReachedError, NbPlayersPerTeamsLimitReachedError, TeamDoesNotExistsError} from "./BitarenaChallengeErrors.sol";
import {PlayerJoinsTeam, TeamCreated} from "./BitarenaChallengeEvents.sol";

contract BitarenaChallenge is Context, AccessControlDefaultAdminRules{

    string private s_name;
    string private s_game;
    string private s_platform;
    uint16 private s_nbTeams;
    uint16 private s_nbTeamPlayers;
    uint private s_startAt;
    uint private s_amountPerPlayer;

    uint16 private s_teamCounter;
    bool private s_isPrivate;
    bool private s_isCanceled;
    address private s_admin;
    address private s_litigationAdmin;
    address private s_creator;

    mapping(uint16 teamIndex => address[] players) private s_players;

    bytes32 public constant CHALLENGE_ADMIN_ROLE = keccak256("CHALLENGE_ADMIN_ROLE");
    bytes32 public constant CHALLENGE_LITIGATION_ADMIN_ROLE = keccak256("CHALLENGE_LITIGATION_ADMIN_ROLE");
    bytes32 public constant CHALLENGE_CREATOR_ROLE = keccak256("CHALLENGE_CREATOR_ROLE");

    constructor(
        address _challengeAdmin,
        address _challengeLitigationAdmin,
        address _challengeCreator,
        string memory _name,
        string memory _game,
        string memory _platform,
        uint16 _nbTeams,
        uint16 _nbTeamPlayers,
        uint _amountPerPlayer,
        uint _startAt,
        bool _isPrivate
    ) AccessControlDefaultAdminRules(1 days, _challengeAdmin) {
        s_admin = _challengeAdmin;
        s_litigationAdmin = _challengeLitigationAdmin;
        s_creator = _challengeCreator;
        s_name = _name;
        s_game = _game;
        s_platform = _platform;
        s_nbTeams = _nbTeams;
        s_nbTeamPlayers = _nbTeamPlayers;
        s_amountPerPlayer = _amountPerPlayer;
        s_startAt = _startAt;
        s_isPrivate = _isPrivate;
        s_isCanceled = false;
        _grantRole(CHALLENGE_ADMIN_ROLE, _challengeAdmin);
        _grantRole(CHALLENGE_CREATOR_ROLE, _challengeCreator);
        s_teamCounter = 0;
    }


    function createTeam() internal {
        s_teamCounter++;
        //if (s_teamCounter > s_nbTeams) revert NbTeamsLimitReachedError();

        //If a team is created for the first time, we add the creator in this team.
        // Otherwise we add the creator of the team in the created team
        if (s_teamCounter == 1) {
            s_players[s_teamCounter].push(s_creator);
            emit PlayerJoinsTeam(s_teamCounter, s_creator);
        }
        else {
            s_players[s_teamCounter].push(_msgSender());
            emit PlayerJoinsTeam(s_teamCounter, _msgSender());
        }
        emit TeamCreated(s_teamCounter);
    }

    function joinTeam(uint16 _teamIndex) internal {
        address[] storage existingPlayers = s_players[_teamIndex];
        if (existingPlayers.length == s_nbTeamPlayers) revert NbPlayersPerTeamsLimitReachedError();
        if (_teamIndex > s_teamCounter) revert TeamDoesNotExistsError();

        existingPlayers.push(_msgSender());
        s_players[_teamIndex] = existingPlayers; 
    }

    /**
     * @dev Function that will be callable by front end. 
     * If value of _teamIndex equals 0 then it's a creation team intent
     * Otherwise the player wants to join the team with specified index
     * @param _teamIndex : index of the team
     */
    function joinOrCreateTeam(uint16 _teamIndex) public {
        //Intent to create a new team 
        if (_teamIndex == 0) {
            createTeam();
        }
        else {
            joinTeam(_teamIndex);
        }
    }

    /**
     * @dev Fonction receive pour accepter les paiements en Ether
     */
    receive() external payable {
        // Logique optionnelle ici, si nécessaire
    }

    /**
     * @dev Fonction fallback pour gérer les appels de fonction inconnus et accepter les paiements en Ether
     */
    fallback() external payable {
        // Logique optionnelle ici, si nécessaire
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
    function getName() external view returns (string memory) {
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
    function getGame() external view returns (string memory) {
        return s_game;
    }

    /**
     * @dev getter for state variable s_platform
     */
    function getPlatform() external view returns (string memory) {
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
    function getChallengeStartDate() external view returns (uint) {
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
    function getAmountPerPlayer() external view returns (uint) {
        return s_amountPerPlayer;
    }

    /**
     * @dev setter for state variable s_amountPerPlayer
     */
    function setAmountPerPlayer(uint _amountPerPlayer) internal {
        s_amountPerPlayer = _amountPerPlayer;
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


}