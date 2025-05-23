// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

/*
Replace with these imports to test in Remix
import {AccessControlDefaultAdminRules} from "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {ReentrancyGuard} from "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/utils/ReentrancyGuard.sol";
import {Context} from "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/utils/Context.sol";
*/
import {AccessControlDefaultAdminRules} from "openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ChallengeParams} from "./struct/ChallengeParams.sol";
import {IBitarenaChallengesData} from "./interfaces/IBitarenaChallengesData.sol";
import {IBitarenaChallenge} from "./interfaces/IBitarenaChallenge.sol";
import {CHALLENGE_ADMIN_ROLE, CHALLENGE_EMERGENCY_ADMIN_ROLE, CHALLENGE_DISPUTE_ADMIN_ROLE, CHALLENGE_CREATOR_ROLE, DELAY_START_VICTORY_CLAIM_BY_DEFAULT, DELAY_END_VICTORY_CLAIM_BY_DEFAULT, 
    DELAY_START_DISPUTE_PARTICIPATION_BY_DEFAULT, DELAY_END_DISPUTE_PARTICIPATION_BY_DEFAULT,
    GAMER_ROLE, FEE_PERCENTAGE_AMOUNT_BY_DEFAULT, FEE_PERCENTAGE_DISPUTE_AMOUNT_BY_DEFAULT, PERCENTAGE_BASE} from "./BitarenaChallengeConstants.sol";

contract BitarenaChallenge is 
    Context, AccessControlDefaultAdminRules, ReentrancyGuard, Pausable, 
    IBitarenaChallenge {

    IBitarenaChallengesData private immutable s_challengesData;

    // aderyn-ignore-next-line(state-variable-could-be-immutable)
    string private s_game; 
    // aderyn-ignore-next-line(state-variable-could-be-immutable)
    string private s_platform;

    uint16 private immutable s_nbTeams;
    uint16 private immutable s_nbTeamPlayers;
    uint16 private s_feePercentage;
    uint16 private s_feePercentageDispute;
    uint16 private s_teamCounter;
    uint16 private s_winnerTeam;

    bool private immutable s_isPrivate;
    bool private s_isCanceled;
    bool private s_isPoolWithdrawed;

    uint256 private immutable s_startAt;
    uint256 private immutable s_amountPerPlayer;
    uint256 private s_delayStartVictoryClaim;
    uint256 private s_delayEndVictoryClaim;
    uint256 private s_delayStartDisputeParticipation;
    uint256 private s_delayEndDisputeParticipation;
    uint256 private s_challengePool;
    uint256 private s_disputePool;

    address private immutable s_admin;
    address private immutable s_disputeAdmin;
    address private immutable s_emergencyAdmin;
    address private immutable s_creator;
    address private immutable s_factory;

    mapping(uint16 teamIndex => address[] players) private s_teams;
    mapping(address player => uint16 teamNumber) private s_players;
    mapping(uint16 teamIndex => bool winner) private s_winners;
    mapping(uint16 teamIndex => address disputeParticipant) private s_disputeParticipants;

    uint16[] private s_disputeTeams;
    uint16[] private s_claimVictoryTeams;

    constructor(ChallengeParams memory params) payable AccessControlDefaultAdminRules(1 days, params.challengeAdmin) {
        s_challengesData = IBitarenaChallengesData(params.challengesData);
        s_factory = params.factory;
        s_admin = params.challengeAdmin;
        s_disputeAdmin = params.challengeDisputeAdmin;
        s_emergencyAdmin = params.challengeEmergencyAdmin;
        s_creator = params.challengeCreator;
        s_game = params.game;
        s_platform = params.platform;
        s_nbTeams = params.nbTeams;
        s_nbTeamPlayers = params.nbTeamPlayers;
        s_amountPerPlayer = params.amountPerPlayer;
        s_startAt = params.startAt;
        s_isPrivate = params.isPrivate;
        s_isCanceled = false;
        s_isPoolWithdrawed = false;
        s_teamCounter = 0;
        s_winnerTeam= 0;
        s_challengePool = 0;
        s_feePercentage = FEE_PERCENTAGE_AMOUNT_BY_DEFAULT;
        s_feePercentageDispute = FEE_PERCENTAGE_DISPUTE_AMOUNT_BY_DEFAULT;
        s_delayStartVictoryClaim = DELAY_START_VICTORY_CLAIM_BY_DEFAULT;
        s_delayEndVictoryClaim = DELAY_END_VICTORY_CLAIM_BY_DEFAULT;
        s_delayStartDisputeParticipation = DELAY_START_DISPUTE_PARTICIPATION_BY_DEFAULT;
        s_delayEndDisputeParticipation = DELAY_END_DISPUTE_PARTICIPATION_BY_DEFAULT;
        _grantRole(CHALLENGE_ADMIN_ROLE, params.challengeAdmin);
        _grantRole(CHALLENGE_EMERGENCY_ADMIN_ROLE, params.challengeEmergencyAdmin);
        _grantRole(CHALLENGE_CREATOR_ROLE, params.challengeCreator);
        _grantRole(CHALLENGE_DISPUTE_ADMIN_ROLE, params.challengeDisputeAdmin);
    }

    /**
     * @dev Modifier for the "joinTeam" function
     */
    // aderyn-ignore-next-line(modifier-used-only-once)
    modifier checkJoinTeam(uint16 _teamIndex) {
        if (s_teams[_teamIndex].length == s_nbTeamPlayers) revert NbPlayersPerTeamsLimitReachedError();
        if (_teamIndex > s_teamCounter) revert TeamDoesNotExistsError();        
        if (s_isCanceled) revert ChallengeCanceledError();
        if (block.timestamp >= s_startAt) revert TimeElapsedToJoinTeamError();
        if (msg.value < s_amountPerPlayer && _msgSender() != s_factory) revert BalanceChallengePlayerError();
        _;
    }

    // aderyn-ignore-next-line(modifier-used-only-once)
    modifier checkCreateTeam() {
        if (msg.value < s_amountPerPlayer && _msgSender() != s_factory) revert BalanceChallengePlayerError();
        _;
    }

    /**
     * @dev Modifier for the "claimVictory" function
     *  Check on : 
     *  - delays are OK
     *  - roles are OK
     *  - not possible to claim victory for a team twice
     *  - Challenge is not canceled
     * 
     */
    // aderyn-ignore-next-line(modifier-used-only-once)
    modifier checkClaimVictory() {
        address sender = _msgSender();
        uint16 _teamIndex = getTeamOfPlayer(sender);
        uint256 startClaimTime = s_startAt + s_delayStartVictoryClaim;
        
        if (s_delayStartVictoryClaim == 0 || s_delayEndVictoryClaim == 0) revert DelayClaimVictoryNotSet();
        if (!isAuthorizedPlayer(sender)) revert ClaimVictoryNotAuthorized();
        if (s_winners[_teamIndex] == true) revert TeamAlreadyClaimedVictoryError();
        if (block.timestamp < (startClaimTime)) revert TimeTooSoonToClaimVictoryError();
        if (block.timestamp > (startClaimTime + s_delayEndVictoryClaim)) revert TimeElapsedToClaimVictoryError();
        if (s_isCanceled) revert ChallengeCanceledError();
        _;
    }

    /**
     * @dev Modifier for the "participateToDispute" function
     * Controls are : 
     *  - delay to claim victory must be set
     *  - dispute participation is required
     *  - a dispute must exist
     *  - only a GAMER or challenge CREATOR can participate to a dispute 
     *  - a disputer can not participate twice
     *  - a dispute participation is only allowed after the delay of claim victory so after startat + delayStartClaimVictory + delayEndClaimVictory
     *  - only a team that claim victory can participate to a dispute
     */
    // aderyn-ignore-next-line(modifier-used-only-once)
    modifier checkDisputeParticipation() {
        address sender = _msgSender();
        if (getDelayStartVictoryClaim() == 0 || getDelayEndVictoryClaim() == 0) revert DelayClaimVictoryNotSet();
        if (s_feePercentageDispute == 0) revert FeeDisputeNotSetError();
        uint256 disputeParticipationAmount = getDisputeAmountParticipation();
        if (msg.value < disputeParticipationAmount) revert NotSufficientAmountForDisputeError();
        if (!atLeast2TeamsClaimVictory()) revert NoDisputeError();
        if (!isAuthorizedPlayer(sender)) revert DisputeParticipationNotAuthorizedError();
        uint16 teamIndex = getTeamOfPlayer(sender);
        if (teamIsDisputer(teamIndex)) revert TeamOfSignerAlreadyParticipatesInDisputeError();
        if (block.timestamp > (s_startAt + s_delayStartVictoryClaim + s_delayEndVictoryClaim + s_delayStartDisputeParticipation + s_delayEndDisputeParticipation)) revert TimeElapsedForDisputeParticipationError();
        if (s_winners[teamIndex] == false) revert TeamDidNotClaimVictoryError();
        _;
    }

    /**
     * Modifier for 'unclaimVictory' fonction
     */
    /*
    modifier checkUnclaimVictory() {
        if (s_delayStartVictoryClaim == 0 || s_delayEndVictoryClaim == 0) revert DelayUnclaimVictoryNotSet();
        if (!hasRole(CHALLENGE_CREATOR_ROLE, _msgSender()) && !hasRole(GAMER_ROLE, _msgSender())) revert UnclaimVictoryNotAuthorized();
        uint16 _teamIndex = getTeamOfPlayer(_msgSender());
        if (block.timestamp > (s_startAt + s_delayStartVictoryClaim + s_delayEndVictoryClaim)) revert TimeElapsedToUnclaimVictoryError();
        if (s_isCanceled) revert ChallengeCanceledError();
        _;
    }*/

    /**
     * After a dispute occurs the ADMIN of the challenge must decide and reveal which team is the winner.
     * So controls for that action are : 
     *   - a dispute must contain 2 participants at least
     *   - the team choosed by the admin must exists and must be a participant of the dispute
     */
    // aderyn-ignore-next-line(modifier-used-only-once)
    modifier checkRevealWinnerAfterDispute(uint16 _teamIndex) {
        if (getDisputeParticipantsCount() < 2) revert RevealWinnerImpossibleDueToTooFewDisputersError();
        if (_teamIndex > s_teamCounter) revert TeamDoesNotExistsError();
        if (!teamIsDisputer(_teamIndex)) revert TeamIsNotDisputerError();
        _;
    }

    /**
     * After a dispute occurs and the ADMIN revealed which team is the winner, the team member can withdraw the pool
     * Controls for that action must be : 
     *   - only a GAMER or challenge CREATOR can withdraw the challenge pool
     *   - this action is possible only after the dispute participation period
     *   - a dispute must exist (so with 2 participants at least)
     *   - impossible to withdraw the pool if the winner has not been revealed yet with at least 2 disputers
     *   - only the member of the team who won can withdraw the challenge pool
     */
    // aderyn-ignore-next-line(modifier-used-only-once)
    modifier checkWithdrawPool() {
        address sender = _msgSender();
        if (!isAuthorizedPlayer(sender)) revert WithdrawPoolNotAuthorized();
        if (block.timestamp < (s_startAt + s_delayStartVictoryClaim + s_delayEndVictoryClaim + s_delayStartDisputeParticipation + s_delayEndDisputeParticipation)) revert MustWaitForEndDisputePeriodError();
        if (s_winnerTeam == 0) revert WinnerNotRevealedYetError();
        uint16 teamIndex = getTeamOfPlayer(sender);
        if (s_winnerTeam != 0 && teamIndex != s_winnerTeam) revert WithdrawPoolByLooserTeamImpossibleError();
        if (getIsPoolWithdrawed()) revert ChallengePoolAlreadyWithdrawed();
        _;
    }

    /**
     * @dev Entry point for front application to create or join a team 
     */
    function createOrJoinTeam(uint16 _teamIndex) external payable {
        if (_teamIndex == 0) {
            createTeam();
        }
        else {
            joinTeam(_teamIndex);
        }
        s_challengesData.updateChallengePool(address(this), s_challengePool);
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
    // aderyn-ignore-next-line(internal-function-used-once)
    function joinTeam(uint16 _teamIndex) internal checkJoinTeam(_teamIndex) {
        address sender = _msgSender();
        joinTeamInternal(_teamIndex, sender);
        emit PlayerJoinsTeam(_teamIndex, sender);
    }

    /**
     * @dev Create a team
     */    
    // aderyn-ignore-next-line(internal-function-used-once)
    function createTeam() internal checkCreateTeam() {
        unchecked {
            ++s_teamCounter;
        }
        if (s_teamCounter > s_nbTeams) revert NbTeamsLimitReachedError();
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
        bool successGrantRole = _grantRole(GAMER_ROLE, _player);
        if (!successGrantRole) revert RoleGrantFailed();
        incrementChallengePool(s_amountPerPlayer);
        // Ajouter le challenge à l'historique du joueur
        ChallengeParams memory _challengeParams = ChallengeParams({
            factory: s_factory,
            challengesData: address(s_challengesData),
            challengeAdmin: s_admin,
            challengeDisputeAdmin: s_disputeAdmin,
            challengeEmergencyAdmin: s_emergencyAdmin,
            challengeCreator: s_creator,
            game: s_game,
            platform: s_platform,
            nbTeams: s_nbTeams,
            nbTeamPlayers: s_nbTeamPlayers,
            amountPerPlayer: s_amountPerPlayer,
            startAt: s_startAt,
            isPrivate: s_isPrivate
        });
        s_challengesData.addChallengeToPlayerHistory(_player, address(this), _challengeParams, _teamIndex);
    }

    
    /**
     * @dev It can be done only between (s_startAt + s_delayStartVictoryClaim) and (s_startAt + s_delayStartVictoryClaim + s_delayEndVictoryClaim)
     * 
     */
    function claimVictory() external checkClaimVictory() whenNotPaused {
        address sender = _msgSender();
        uint16 teamIndex = getTeamOfPlayer(sender); 
        s_winners[teamIndex] = true;
        s_claimVictoryTeams.push(teamIndex);
        if (s_claimVictoryTeams.length == 1) {
            s_winnerTeam = teamIndex;
        }
        else {
            s_winnerTeam = 0;
        }
        s_challengesData.updateWinnersClaimedCount(address(this));
        s_challengesData.updateWinnerTeam(address(this), s_winnerTeam);
        emit VictoryClaimed(teamIndex, sender);   
    }

    /**
     * @dev If a team decides to unclaimVictory after claiming it, we must provide a fonction for that
     * Not suggested in this V1. May be later if needed
     */
    /*
    function unclaimVictory() public checkUnclaimVictory() {
        uint16 _teamIndex = getTeamOfPlayer(_msgSender());
        s_winners[_teamIndex] = false;
        
        for (uint256 i = 0; i < s_claimVictoryTeams.length; i++) {
            if (s_claimVictoryTeams[i] == _teamIndex) {
                // Déplacer le dernier élément à la place de celui à supprimer
                s_claimVictoryTeams[i] = s_claimVictoryTeams[s_claimVictoryTeams.length - 1];
                // Supprimer le dernier élément
                s_claimVictoryTeams.pop();
                break;
            }
        }

        //If there is no more element in the array of teams that claimed victory we must reset team index of winner to value 0
        if (s_claimVictoryTeams.length == 0) {
            s_winnerTeam = 0;
        }

        emit VictoryUnclaimed(_teamIndex, _msgSender());
    }
    */

    /**
     * This function only callable by Admin of the challenge mus be call in case a disputer finally 
     * does not want to participate to the dispute, so we must refund the only participant to the dispute
     */
    /*function refundDisputeAmount() public onlyRole(CHALLENGE_ADMIN_ROLE) checkRefundDisputeAmount() nonReentrant {
        uint16 teamInDispute = s_disputeTeams[0];
        address disputeParticipant = s_disputeParticipants[teamInDispute];
        (bool success, ) = disputeParticipant.call{value: getDisputeAmountParticipation()}("");
        if (!success) revert SendMoneyBackToPlayersError();
    }*/

    /**
     * @dev After many teams participate to a dispute, the challenge ADMIN reveal which team is the winner by indicating which team is the winner
     */
    // aderyn-ignore-next-line(centralization-risk)
    function revealWinnerAfterDispute(uint16 _teamIndex) external onlyRole(CHALLENGE_DISPUTE_ADMIN_ROLE) checkRevealWinnerAfterDispute(_teamIndex) {
        s_winnerTeam = _teamIndex;
        s_challengesData.updateWinnerTeam(address(this), _teamIndex);
        emit RevealWinner(_teamIndex, _msgSender());
    }    

    /**
     * @dev Returns true if the team identified by '_teamIndex' is a dispute participant
     * and false otherwise
     */
    function teamIsDisputer(uint16 _teamIndex) internal view returns (bool) {
        address participant = s_disputeParticipants[_teamIndex];
        return (participant != address(0));
    }

    /**
     * @dev
     */
    // aderyn-ignore-next-line(centralization-risk)
    function setFeePercentageDispute(uint16 _percentage) external onlyRole(CHALLENGE_ADMIN_ROLE) {
        s_feePercentageDispute = _percentage;
        emit FeePercentageDisputeUpdated(_percentage);
    }

    /**
     * @dev
     */
    // aderyn-ignore-next-line(centralization-risk)
    function setFeePercentage(uint16 _percentage) external onlyRole(CHALLENGE_ADMIN_ROLE) {
        s_feePercentage = _percentage;
        emit FeePercentageUpdated(_percentage);
    }

    /** 
     *  @dev : Only one player create a dispute for his team.
     */
    function participateToDispute() external payable checkDisputeParticipation() whenNotPaused {
        address sender = _msgSender();
        uint16 teamSigner = getTeamOfPlayer(sender);
        s_disputeParticipants[teamSigner] = sender; 
        s_disputeTeams.push(teamSigner);
        // The first team to participate to the dispute is revealed as winner
        // Then, if no other teams participate to the dispute, the winer is the first team to participate
        if (s_disputeTeams.length == 1) {
            s_winnerTeam = teamSigner;
        }
        else {
            // If a second team participates to the dispute we reset the winner to 0 = no winner
            s_winnerTeam = 0;
        }
        
        incrementDisputePool(getDisputeAmountParticipation());
        emit ParticipateToDispute(sender);
        s_challengesData.updateWinnerTeam(address(this), s_winnerTeam);
    }

    /**
     * @dev Mettre le contrat en pause
     * Only the emergency admin can call this function
     */ 
    // aderyn-ignore-next-line(centralization-risk)
    function pause() external onlyRole(CHALLENGE_EMERGENCY_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Reprendre le contrat
     * Only the emergency admin can call this function
     */
    // aderyn-ignore-next-line(centralization-risk)
    function unpause() external onlyRole(CHALLENGE_EMERGENCY_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * Delay to start the victory claim (after the start date).
     * Ex : 1 days
     * 
     * @dev
     */
    // aderyn-ignore-next-line(centralization-risk)
    function setDelayStartForVictoryClaim(uint256 _delayStartVictoryClaim) external onlyRole(CHALLENGE_ADMIN_ROLE) {
        if (s_delayEndVictoryClaim > 0 && _delayStartVictoryClaim > s_delayEndVictoryClaim) revert DelayStartGreaterThanDelayEnd();
        s_delayStartVictoryClaim = _delayStartVictoryClaim;
        emit DelayStartForVictoryClaimUpdated(_delayStartVictoryClaim);
    }

    /**
     * Delay to end the victory claim (after the start date of victory claim).
     * Ex : 5 hours
     * 
     * @dev
     */
    // aderyn-ignore-next-line(centralization-risk)
    function setDelayEndForVictoryClaim(uint256 _delayEndVictoryClaim) external onlyRole(CHALLENGE_ADMIN_ROLE) {
        if (s_delayStartVictoryClaim > 0 && s_delayStartVictoryClaim > _delayEndVictoryClaim) revert DelayStartGreaterThanDelayEnd();
        s_delayEndVictoryClaim = _delayEndVictoryClaim;
        emit DelayEndForVictoryClaimUpdated(_delayEndVictoryClaim);
    }

    /**
     * Delay to start the dispute participation (after the end victory claim).
     * Ex : 1 hours
     * 
     * @dev
     */
    // aderyn-ignore-next-line(centralization-risk)
    function setDelayStartDisputeParticipation(uint256 _delayStartDisputeParticipation) external onlyRole(CHALLENGE_DISPUTE_ADMIN_ROLE) {
        if (s_delayEndDisputeParticipation > 0 && _delayStartDisputeParticipation > s_delayEndDisputeParticipation) revert DelayStartGreaterThanDelayEnd();
        s_delayStartDisputeParticipation = _delayStartDisputeParticipation;
        emit DelayStartDisputeParticipationUpdated(_delayStartDisputeParticipation);
    }

    /**
     * Delay to end the dispute participation (after the start date of dispute participation).
     * Ex : 5 hours
     * 
     * @dev
     */
    // aderyn-ignore-next-line(centralization-risk)
    function setDelayEndDisputeParticipation(uint256 _delayEndDisputeParticipation) external onlyRole(CHALLENGE_DISPUTE_ADMIN_ROLE) {
        if (s_delayStartDisputeParticipation > 0 && s_delayStartDisputeParticipation > _delayEndDisputeParticipation) revert DelayStartGreaterThanDelayEnd();
        s_delayEndDisputeParticipation = _delayEndDisputeParticipation;
        emit DelayEndDisputeParticipationUpdated(_delayEndDisputeParticipation);
    }

    /**
     * @dev Nothing special to implemnt on 'receive'
     */
    receive() external payable {
        
    }
    /**
     * @dev increment the challenge pool
     */
    // aderyn-ignore-next-line(internal-function-used-once)
    function incrementChallengePool(uint256 _amount) internal {
        s_challengePool += _amount;
    }

    /**
     * @dev increment the challenge pool
     */
    // aderyn-ignore-next-line(internal-function-used-once)
    function incrementDisputePool(uint256 _amount) internal {
        s_disputePool += _amount;
    }

    /**
     * @dev Only the challengecreator can cancel  a challenge only before _startDate
     */
    // aderyn-ignore-next-line(centralization-risk)
    function cancelChallenge() external onlyRole(CHALLENGE_CREATOR_ROLE) {
        if (block.timestamp > s_startAt) revert ChallengeCancelAfterStartDateError();
        setIsCanceled(true);
        returnMoneyBackDueToChallengeCancel();
        emit ChallengeCanceled(address(this));
    }

    /**
     * After the challenge creator cancel the challenge, the money must be sent back to players
     */
    // aderyn-ignore-next-line(internal-function-used-once)
    function returnMoneyBackDueToChallengeCancel() internal nonReentrant {
        uint16 teamCount = s_teamCounter;

        //Reset the challenge pool
        s_challengePool = 0;

        for (uint16 i = 1; i <= teamCount;) {
            address[] memory teamPlayers = s_teams[i];
            uint256 playersLength = teamPlayers.length;
            for (uint256 j = 0; j < playersLength;) {
                address player = teamPlayers[j];
                (bool success, ) = player.call{value: s_amountPerPlayer}("");
                if (!success) revert SendMoneyBackToPlayersError();
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    /**
     * @dev By calling this function after the victory claim period, it calculates if there's a dispute
     * meaning if at least 2 teams claim the victory among all the teams
     * 
     */
    function atLeast2TeamsClaimVictory() public view returns (bool) {
        return (s_claimVictoryTeams.length > 1);
    }

    /**
     * @dev Returns true if at least 2 teams participate to a dispute
     */
    function atLeast2TeamsParticipateToDispute() external view returns (bool) {
        return (getDisputeParticipantsCount() > 1);
    }

    /**
     * @dev Returns true if at least 1 team participate to a dispute
     */
    function atLeast1TeamParticipateToDispute() external view returns (bool) {
        return (getDisputeParticipantsCount() >= 1);
    }

    /**
     * @dev Fee amount for Bitarena protocol
     */
    function calculateFeeAmount() public view returns (uint256) {
        return (getFeePercentage() * getChallengePool()) / PERCENTAGE_BASE;
    }

    /**
     * @dev 
     */
    function calculatePoolAmountToSendBackForWinnerTeam() public view returns (uint256) {
        address[] memory winningTeam = s_teams[s_winnerTeam];
        uint256 playerWinnersCount = winningTeam.length;

        
        uint256 poolAmount = getChallengePool() - calculateFeeAmount();
        uint256 remainder = poolAmount % playerWinnersCount;
        //We substract the remainder of the euclidian divide in order to make the amount to send back dividable 
        poolAmount = poolAmount - remainder;
        return poolAmount;
    }

    /**
     * @dev 
     * Rules : Only the winner can withdraw the pool
     */
    function withdrawChallengePool() external nonReentrant whenNotPaused checkWithdrawPool()  {
        s_isPoolWithdrawed = true;

        address[] memory winningTeam = s_teams[s_winnerTeam];
        uint256 playerWinnersCount = winningTeam.length;

        uint256 totalPoolAmountForWinner = calculatePoolAmountToSendBackForWinnerTeam();        
        
        //STEP 1: Send dispute amount back to the winner only if there was a dispute
        address disputeParticipant = s_disputeParticipants[s_winnerTeam];
        uint256 amountDispute = 0;
        if (disputeParticipant != address(0)) {
            amountDispute = getDisputeAmountParticipation();
            (bool success1, ) = disputeParticipant.call{value: amountDispute}("");
            if (!success1) revert SendDisputeAmountBackToWinnerError();
        }    
        
        //STEP 2 : Send challenge pool to players of winner team
        uint256 amountPerPlayer = totalPoolAmountForWinner / playerWinnersCount;

        for (uint256 i = 0; i < playerWinnersCount; i++) {
            (bool success2, ) = winningTeam[i].call{value: amountPerPlayer}("");
            if (!success2) revert SendMoneyBackToPlayersError();
        }     

        //STEP 3 : Decrements the different pool amount
        uint256 poolAmountRemainingforAdmin = s_challengePool - totalPoolAmountForWinner;
        uint256 disputePoolAmountRemainingForAdmin = 0;
        if (disputeParticipant != address(0)) {
            disputePoolAmountRemainingForAdmin = s_disputePool - amountDispute;
        }

        //STEP 4 : Send back dispute fee and pool fee to the admin challenge
        uint256 amountToSendToAdmin = poolAmountRemainingforAdmin + disputePoolAmountRemainingForAdmin;
        (bool success3, ) = s_admin.call{value: amountToSendToAdmin}("");
        if (!success3) revert SendMoneyBackToAdminError();
         
        s_challengesData.setChallengeAsEnded(address(this)); 
        emit PoolChallengeWithdrawed(s_winnerTeam, _msgSender());
    }

    /**
     * @dev return true if a signer is authorized
     */
    function isAuthorizedPlayer(address account) internal view returns (bool) {
        return hasRole(CHALLENGE_CREATOR_ROLE, account) || hasRole(GAMER_ROLE, account);
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
     * @dev getter for state variable s_isPoolWithdrawed
     */
    function getIsPoolWithdrawed() public view returns (bool) {
        return s_isPoolWithdrawed;
    }

    /**
     * @dev setter for state variable s_isCanceled
     */
    // aderyn-ignore-next-line(internal-function-used-once)
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
    function getDelayStartVictoryClaim() public view returns (uint256) {
        return s_delayStartVictoryClaim;
    }

    /**
     * @dev getter for state variable s_delayEndVictoryClaim
     */
    function getDelayEndVictoryClaim() public view returns (uint256) {
        return s_delayEndVictoryClaim;
    }

    /**
     * @dev getter for state variable s_delayStartDisputeParticipation
     */
    function getDelayStartDisputeParticipation() external view returns (uint256) {
        return s_delayStartDisputeParticipation;
    }

    /**
     * @dev getter for state variable s_delayEndDisputeParticipation
     */
    function getDelayEndDisputeParticipation() external view returns (uint256) {
        return s_delayEndDisputeParticipation;
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
    function getChallengePool() public view returns (uint256) {
        return s_challengePool;
    }

    /**
     * @dev get the value of the amount of the dispute participation
     */
    function getDisputeAmountParticipation() public view returns (uint256) {
        uint256 disputeParticipationAmount = s_challengePool * s_feePercentageDispute;
        disputeParticipationAmount = disputeParticipationAmount / PERCENTAGE_BASE;
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
    function getFeePercentage() public view returns (uint16) {
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
    function getDisputeParticipants(uint16 _teamIndex) external view returns (address) {
        return s_disputeParticipants[_teamIndex];
    }

    /**
     * @dev get the state var "s_winners"
     */
    function getWinnerClaimed(uint16 _teamIndex) external view returns (bool) {
        return s_winners[_teamIndex];
    }

    /**
     * @dev get the number of team that claimed victory
     */
    function getWinnersClaimedCount() external view returns (uint256) {
        return s_claimVictoryTeams.length;
    }

    /**
     * @dev get the state var "s_winnerTeam"
     */
    function getWinnerTeam() external view returns (uint16) {
        return s_winnerTeam;
    }

}