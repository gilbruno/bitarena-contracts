// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {AccessControlDefaultAdminRules} from "openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

contract BitarenaChallenge is AccessControlDefaultAdminRules{

    string private s_name;
    string private s_game;
    string private s_platform;
    uint16 private s_nbTeams;
    uint16 private s_nbTeamPlayers;
    uint private s_startAt;
    bool private s_isPrivate;
    bool private s_isCanceled;
    address private s_admin;
    address private s_litigationAdmin;
    address private s_creator;


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
        _startAt = s_startAt;
        _isPrivate = s_isPrivate;
        s_isCanceled = false;
        _grantRole(CHALLENGE_ADMIN_ROLE, _challengeAdmin);
        

    }

    function cancelChallenge() public onlyRole(CHALLENGE_CREATOR_ROLE) {
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
     * @dev getter for state variable s_isCanceled
     */
    function setIsCanceled(bool _isCanceled) internal {
        s_isCanceled = _isCanceled;
    }
}