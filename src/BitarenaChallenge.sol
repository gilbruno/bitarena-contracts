// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {AccessControlDefaultAdminRules} from "openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {BalanceChallengePlayerError, ChallengeCanceledError, ChallengeCancelAfterStartDateError, ClaimVictoryNotAuthorized, 
    DelayClaimVictoryNotSet, DelayUnclaimVictoryNotSet, DisputeExistsError, DisputeParticipationNotAuthorizedError, FeeDisputeNotSetError, NbTeamsLimitReachedError, 
    NbPlayersPerTeamsLimitReachedError, NoDisputeError, NotSufficientAmountForDisputeError, NotTeamMemberError, NoDisputeParticipantsError, RefundImpossibleDueToTooManyDisputeParticipantsError, 
    SendMoneyBackToPlayersError, TeamDoesNotExistsError, TeamOfSignerAlreadyParticipatesInDisputeError, TimeElapsedToClaimVictoryError, TimeElapsedToUnclaimVictoryError, TimeElapsedToCreateDisputeError, 
    TimeElapsedToJoinTeamError, WithdrawPoolNotAuthorized, UnclaimVictoryNotAuthorized} from "./BitarenaChallengeErrors.sol";
import {PlayerJoinsTeam, TeamCreated, Debug, VictoryClaimed, VictoryUnclaimed} from "./BitarenaChallengeEvents.sol";
import {ChallengeParams} from "./ChallengeParams.sol";
import {CHALLENGE_ADMIN_ROLE, CHALLENGE_DISPUTE_ADMIN_ROLE, CHALLENGE_CREATOR_ROLE, GAMER_ROLE, FEE_PERCENTAGE_AMOUNT_BY_DEFAULT, FEE_PERCENTAGE_DISPUTE_AMOUNT_BY_DEFAULT} from "./BitarenaChallengeConstants.sol";

contract BitarenaChallenge is Context, AccessControlDefaultAdminRules{

    bytes32 private s_game;
    bytes32 private s_platform;

    uint16 private immutable s_nbTeams;
    uint16 private immutable s_nbTeamPlayers;
    uint16 private s_feePercentage;
    uint16 private s_feePercentageDispute;
    uint16 private s_teamCounter;
    uint16 private s_winnersCount;
    
    uint256 private immutable s_startAt;
    uint256 private immutable s_amountPerPlayer;
    uint256 private s_delayStartVictoryClaim;
    uint256 private s_delayEndVictoryClaim;
    uint256 private s_challengePool;
    uint256 private s_disputePool;

    bool private s_isPrivate;
    bool private s_isCanceled;

    address private s_admin;
    address private s_disputeAdmin;
    address private immutable s_creator;
    address private immutable s_factory;

    mapping(uint16 teamIndex => address[] players) private s_teams;
    mapping(address player => uint16 teamNumber) private s_players;
    mapping(uint16 teamIndex => bool winner) private s_winners;
    mapping(uint16 teamIndex => address disputeParticipant) private s_disputeParticipants;

    uint16[] private s_disputeTeams;

    constructor(ChallengeParams memory params) AccessControlDefaultAdminRules(1 days, params.challengeAdmin) {
        s_factory = params.factory;
        s_admin = params.challengeAdmin;
        s_disputeAdmin = params.challengeDisputeAdmin;
        s_creator = params.challengeCreator;
        s_game = params.game;
        s_platform = params.platform;
        s_nbTeams = params.nbTeams;
        s_nbTeamPlayers = params.nbTeamPlayers;
        s_amountPerPlayer = params.amountPerPlayer;
        s_startAt = params.startAt;
        s_isPrivate = params.isPrivate;
        s_isCanceled = false;
        s_teamCounter = 0;
        s_winnersCount = 0;
        s_challengePool = 0;
        s_feePercentage = FEE_PERCENTAGE_AMOUNT_BY_DEFAULT;
        s_feePercentageDispute = FEE_PERCENTAGE_DISPUTE_AMOUNT_BY_DEFAULT;
        s_delayStartVictoryClaim = 0;
        s_delayEndVictoryClaim = 0;
        _grantRole(CHALLENGE_ADMIN_ROLE, params.challengeAdmin);
        _grantRole(CHALLENGE_CREATOR_ROLE, params.challengeCreator);
        _grantRole(CHALLENGE_DISPUTE_ADMIN_ROLE, params.challengeDisputeAdmin);
    }

    /**
     * @dev Modifier for the "joinTem" function
     */
    modifier checkJoinTeam(uint16 _teamIndex) {
        if (s_teams[_teamIndex].length == s_nbTeamPlayers) revert NbPlayersPerTeamsLimitReachedError();
        if (_teamIndex > s_teamCounter) revert TeamDoesNotExistsError();        
        if (s_isCanceled) revert ChallengeCanceledError();
        if (block.timestamp >= s_startAt) revert TimeElapsedToJoinTeamError();
        if (msg.value < s_amountPerPlayer && _msgSender() != s_factory) revert BalanceChallengePlayerError();
        _;
    }

    /**
     * @dev Modifier for the "claimVictory" function
     */
    modifier checkClaimVictory(uint16 _teamIndex) {
        if (s_delayStartVictoryClaim == 0 || s_delayEndVictoryClaim == 0) revert DelayClaimVictoryNotSet();
        if (!hasRole(CHALLENGE_CREATOR_ROLE, _msgSender()) && !hasRole(GAMER_ROLE, _msgSender())) revert ClaimVictoryNotAuthorized();
        if (_teamIndex > s_teamCounter) revert TeamDoesNotExistsError();
        if (block.timestamp > (s_startAt + s_delayStartVictoryClaim + s_delayEndVictoryClaim)) revert TimeElapsedToClaimVictoryError();
        if (s_players[_msgSender()] != _teamIndex) revert NotTeamMemberError();
        if (s_isCanceled) revert ChallengeCanceledError();
        _;
    }

    /**
     * @dev Modifier for the "participateToDispute" function
     */
    modifier checkDisputeParticipation() {
        if (s_delayStartVictoryClaim == 0 || s_delayEndVictoryClaim == 0) revert DelayClaimVictoryNotSet();
        if (s_feePercentageDispute == 0) revert FeeDisputeNotSetError();
        uint256 disputeParticipationAmount = getDisputeAmountParticipation();
        if (msg.value < disputeParticipationAmount) revert NotSufficientAmountForDisputeError();
        if (!disputeExists()) revert NoDisputeError();
        if (!hasRole(CHALLENGE_CREATOR_ROLE, _msgSender()) && !hasRole(GAMER_ROLE, _msgSender())) revert DisputeParticipationNotAuthorizedError();
        uint16 teamOfSigner = getTeamOfPlayer(_msgSender());
        address participant = s_disputeParticipants[teamOfSigner];
        if (participant != address(0)) revert TeamOfSignerAlreadyParticipatesInDisputeError();
        _;
    }

    /**
     * Modifier for 'unclaimVictory' fonction
     */
    modifier checkUnclaimVictory(uint16 _teamIndex) {
        if (s_delayStartVictoryClaim == 0 || s_delayEndVictoryClaim == 0) revert DelayUnclaimVictoryNotSet();
        if (!hasRole(CHALLENGE_CREATOR_ROLE, _msgSender()) && !hasRole(GAMER_ROLE, _msgSender())) revert UnclaimVictoryNotAuthorized();
        if (_teamIndex > s_teamCounter) revert TeamDoesNotExistsError();
        if (block.timestamp > (s_startAt + s_delayStartVictoryClaim + s_delayEndVictoryClaim)) revert TimeElapsedToUnclaimVictoryError();
        if (s_players[_msgSender()] != _teamIndex) revert NotTeamMemberError();
        if (s_isCanceled) revert ChallengeCanceledError();
        _;
    }

    /**
     * Modifier for 'refundDisputeAmount' fonction
     */
    modifier checkRefundDisputeAmount() {
        if (getDisputeParticipantsCount() > 1) revert RefundImpossibleDueToTooManyDisputeParticipantsError();
        if (getDisputeParticipantsCount() == 0) revert NoDisputeParticipantsError();
        _;
    }

    /**
     * @dev Function that will be callable by front end. 
     * If value of _teamIndex equals 0 then it's a creation team intent
     * Oherwise the player wants to join the team with specified index
     * When you join a team you must pay the 'amountPerPlayer'. 
     * We have an exception when the factory call the function because that's the first team creation by the challenge creator 
     * and he already paid for the challenge.
     * We reject the Tx if a player wants to join a team afetr the challenge start date
     * 
     */
    function joinTeam(uint16 _teamIndex) public payable checkJoinTeam(_teamIndex) {
        joinTeamInternal(_teamIndex, _msgSender());
        emit PlayerJoinsTeam(_teamIndex, _msgSender());
    }

    /**
     * @dev Create a team
     */    
    function createTeam() public payable {
        unchecked {
            ++s_teamCounter;
        }
        
        //If a team is created for the first time, we add the creator of the challenge in this team.
        // Otherwise we add the creator of the team in the created team
        address player = s_teamCounter == 1 ? s_creator : _msgSender();
        s_winners[s_teamCounter] = false;
        joinTeamInternal(s_teamCounter, player);
        emit TeamCreated(s_teamCounter);
    }

    /**
     * @dev 
     */
    function joinTeamInternal(uint16 _teamIndex, address _player) internal {
        s_teams[_teamIndex].push(_player);
        s_players[_player] = _teamIndex;
        _grantRole(GAMER_ROLE, _msgSender());
        incrementChallengePool(s_amountPerPlayer);
    }

    
    /**
     * @dev It can be done only between (s_startAt + s_delayStartVictoryClaim) and (s_startAt + s_delayStartVictoryClaim + s_delayEndVictoryClaim)
     * @param _teamIndex : index of the team
     */
    function claimVictory(uint16 _teamIndex) public checkClaimVictory(_teamIndex) {
        s_winners[_teamIndex] = true;
        s_winnersCount++;
        emit VictoryClaimed(_teamIndex, _msgSender());
    }

    /**
     * @dev If a team decides to unclaimVictory after claiming it, we must provide a fonction for that
     * @param _teamIndex : index of the team
     */
    function unclaimVictory(uint16 _teamIndex) public checkUnclaimVictory(_teamIndex) {
        s_winners[_teamIndex] = true;
        //We decrement only if we have at least 1 winner claimed
        if (s_winnersCount > 0) {
            s_winnersCount--;
        } 
        emit VictoryUnclaimed(_teamIndex, _msgSender());
    }

    /**
     * This function only callable by Admin of the challenge mus be call in case a disputer finally 
     * does not want to participate to the dispute, so we must refund the only participant to the dispute
     */
    function refundDisputeAmount() public onlyRole(CHALLENGE_ADMIN_ROLE) checkRefundDisputeAmount() {
        uint16 teamInDispute = s_disputeTeams[0];
        address disputeParticipant = s_disputeParticipants[teamInDispute];
        (bool success, ) = disputeParticipant.call{value: getDisputeAmountParticipation()}("");
        if (!success) revert SendMoneyBackToPlayersError();
    }

    /**
     * @dev
     */
    function setFeePercentageDispute(uint16 _percentage) public onlyRole(CHALLENGE_ADMIN_ROLE) {
        s_feePercentageDispute = _percentage;
    }

    /**
     * @dev
     */
    function setFeePercentage(uint16 _percentage) public onlyRole(CHALLENGE_ADMIN_ROLE) {
        s_feePercentage = _percentage;
    }

    /** 
     *  @dev : Only one player create a dispute for his team.
     */
    function participateToDispute() public payable checkDisputeParticipation()  {
        uint16 teamSigner = getTeamOfPlayer(_msgSender());
        s_disputeParticipants[teamSigner] = _msgSender(); 
        s_disputeTeams.push(teamSigner);
        incrementDisputePool(getDisputeAmountParticipation());
    }

    /**
     * Delay to start the victory claim (after the start date).
     * Ex : 1 days
     * 
     * @dev
     */
    function setDelayStartForVictoryClaim(uint256 _delayStartVictoryClaim) public onlyRole(CHALLENGE_ADMIN_ROLE) {
        s_delayStartVictoryClaim = _delayStartVictoryClaim;
    }

    /**
     * Delay to end the victory claim (after the start date of victory claim).
     * Ex : 5 hours
     * 
     * @dev
     */
    function setDelayEndForVictoryClaim(uint256 _delayEndVictoryClaim) public onlyRole(CHALLENGE_ADMIN_ROLE) {
        s_delayEndVictoryClaim = _delayEndVictoryClaim;
    }
    /**
     * @dev Nothing special to implemnt on 'receive'
     */
    receive() external payable {
        
    }
    /**
     * @dev increment the challenge pool
     */
    function incrementChallengePool(uint256 _amount) internal {
        s_challengePool += _amount;
    }

    /**
     * @dev increment the challenge pool
     */
    function incrementDisputePool(uint256 _amount) internal {
        s_disputePool += _amount;
    }

    /**
     * @dev Only the challengecreator can cancel  a challenge only before _startDate
     */
    function cancelChallenge() public onlyRole(CHALLENGE_CREATOR_ROLE) {
        if (block.timestamp > s_startAt) revert ChallengeCancelAfterStartDateError();
        setIsCanceled(true);
        returnMoneyBackDueToChallengeCancel();
    }

    /**
     * After the challenge creator cancel the challenge, the money must be sent back to players
     */
    function returnMoneyBackDueToChallengeCancel() internal {
        uint16 teamCount = s_teamCounter;
        for (uint16 i = 1; i <= teamCount; i++) {
            address[] memory teamPlayers = s_teams[i];
            for (uint256 j = 0; j < teamPlayers.length; j++) {
                address player = teamPlayers[j];
                (bool success, ) = player.call{value: s_amountPerPlayer}("");
                if (!success) revert SendMoneyBackToPlayersError();
            }
        }
        //Reset the challenge pool
        s_challengePool = 0;
    }

    /**
     * @dev By calling this function after the victory claim period, it calculates if there's a dispute
     * meaning if at least 2 teams claim the victory among all the teams
     * 
     */
    function disputeExists() public view returns (bool) {
        return (s_winnersCount > 1);
    }


    /**
     * @dev 
     * Rules : Only the winner can withdraw the pool
     */
    function withdrawChallengePool() public {
        if (!hasRole(CHALLENGE_CREATOR_ROLE, _msgSender()) && !hasRole(GAMER_ROLE, _msgSender())) revert WithdrawPoolNotAuthorized();
        if (disputeExists()) revert DisputeExistsError();
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
     * @dev getter for mapping state variable s_teams
     */
    function getTeamsByTeamIndex(uint16 _teamIndex) external view returns (address[] memory) {
        return s_teams[_teamIndex];
    }

    /**
     * @dev getter for mapping state variable s_teams
     * @return the team number of the player
     */
    function getTeamOfPlayer(address _player) public view returns (uint16) {
        return s_players[_player];
    }

    /**
     * @dev getter for state variable s_delayStartVictoryClaim
     */
    function getDelayStartVictoryClaim() external view returns (uint256) {
        return s_delayStartVictoryClaim;
    }

    /**
     * @dev getter for state variable s_delayEndVictoryClaim
     */
    function getDelayEndVictoryClaim() external view returns (uint256) {
        return s_delayEndVictoryClaim;
    }

    /**
     * @dev getter for state variable s_feePercentageDispute
     */
    function getFeePercentageDispute() external view returns (uint16) {
        return s_feePercentageDispute;
    }

    /**
     * @dev getter for state variable s_challengePool
     */
    function getChallengePool() external view returns (uint256) {
        return s_challengePool;
    }

    /**
     * @dev get the value of the amount of the dispute participation
     */
    function getDisputeAmountParticipation() public view returns (uint256) {
        uint256 disputeParticipationAmount = s_challengePool * s_feePercentageDispute;
        disputeParticipationAmount = disputeParticipationAmount / 100;
        return disputeParticipationAmount;
    }

    /**
     * @dev getter for state variable s_disputePool
     */
    function getDisputePool() external view returns (uint256) {
        return s_disputePool;
    }

    /**
     * @dev getter for state variable s_feePercentage
     */
    function getFeePercentage() external view returns (uint16) {
        return s_feePercentage;
    }

    /**
     * @dev getter for state variable s_admin
     */
    function getChallengeAdmin() external view returns (address) {
        return s_admin;
    }

    /**
     * @dev getter for state variable s_disputeAdmin
     */
    function getDisputeAdmin() external view returns (address) {
        return s_disputeAdmin;
    }

    /**
     * @dev get the count of dispute participants 
     */
    function getDisputeParticipantsCount() public view returns (uint256) {
        return s_disputeTeams.length;
    }

    /**
     * @dev getter for state variable s_disputeParticipants
     */
    function getDisputeParticipants(uint16 _teamIndex) public view returns (address) {
        return s_disputeParticipants[_teamIndex];
    }

}