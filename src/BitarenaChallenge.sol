// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {AccessControlDefaultAdminRules} from "openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {ChallengeCancelAfterStartDateError, NbTeamsLimitReachedError, NbPlayersPerTeamsLimitReachedError} from "./BitarenaChallengeErrors.sol";
import {PlayerJoinsTeam, TeamCreated} from "./BitarenaChallengeEvents.sol";

contract BitarenaChallenge is Context, AccessControlDefaultAdminRules{

    string private s_name;
    string private s_game;
    string private s_platform;
    uint16 private s_nbTeams;
    uint16 private s_nbTeamPlayers;
    uint private s_startAt;
    uint private s_amountPerPlayer;

    uint16 s_teamCounter;
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
        _challengeAdmin = s_admin;
        _challengeLitigationAdmin = s_litigationAdmin;
        _challengeCreator = s_creator;
        _name = s_name;
        _game = s_game;
        _platform = s_platform;
        _nbTeams = s_nbTeams;
        _nbTeamPlayers = s_nbTeamPlayers;
        _amountPerPlayer = s_amountPerPlayer;
        _startAt = s_startAt;
        _isPrivate = s_isPrivate;
        s_isCanceled = false;
        _grantRole(CHALLENGE_ADMIN_ROLE, _challengeAdmin);
        _grantRole(CHALLENGE_CREATOR_ROLE, _challengeCreator);

        s_teamCounter++;
    }


    function createTeam() internal {
        s_teamCounter++;
        if (s_teamCounter > s_nbTeams) revert NbTeamsLimitReachedError();

        //If a team is created for the first time, we add the creator in this team
        if (s_teamCounter == 1) {
            s_players[s_teamCounter].push(s_creator);
            emit PlayerJoinsTeam(s_teamCounter, s_creator);
        }
        emit TeamCreated(s_teamCounter);
    }

    function joinTeam(uint16 _teamIndex) internal {
        address[] storage existingPlayers = s_players[_teamIndex];
        if (existingPlayers.length == s_nbTeamPlayers) revert NbPlayersPerTeamsLimitReachedError();

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
    function getNbTeam() external view returns (uint16) {
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
     * @dev getter for mapping state variable s_players
     */
    function getPlayersByTeamIndex(uint16 _teamIndex) external view returns (address[] memory) {
        return s_players[_teamIndex];
    }


}