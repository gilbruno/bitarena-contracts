// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {BitarenaFactory} from "../src/BitarenaFactory.sol";
import {CHALLENGE_ADMIN_ROLE, CHALLENGE_DISPUTE_ADMIN_ROLE, CHALLENGE_CREATOR_ROLE, GAMER_ROLE, FEE_PERCENTAGE_AMOUNT_BY_DEFAULT} from "../src/BitarenaChallengeConstants.sol";
import {BalanceChallengeCreatorError, ChallengeAdminAddressZeroError, 
    ChallengeCounterError, ChallengeCreatorAddressZeroError, ChallengeDisputeAdminAddressZeroError, ChallengeGameError, 
    ChallengeNameError, ChallengePlatformError, ChallengeStartDateError, NbTeamsError, NbPlayersPerTeamsError, 
    SendMoneyToChallengeError} from '../src/BitarenaFactoryErrors.sol';
import {Challenge} from '../src/ChallengeStruct.sol';
import {BitarenaChallenge} from '../src/BitarenaChallenge.sol';
import {BalanceChallengePlayerError, ChallengeCancelAfterStartDateError, ChallengeCanceledError, ChallengePoolAlreadyWithdrawed, ClaimVictoryNotAuthorized, 
    DelayClaimVictoryNotSet, DelayUnclaimVictoryNotSet, DelayStartClaimVictoryGreaterThanDelayEndClaimVictoryError, 
    DisputeExistsError, DisputeParticipationNotAuthorizedError, FeeDisputeNotSetError, NbTeamsLimitReachedError, NbPlayersPerTeamsLimitReachedError, 
    NotSufficientAmountForDisputeError, NoDisputeError, NoDisputeParticipantsError, NotTeamMemberError, RefundImpossibleDueToTooManyDisputeParticipantsError, 
    RevealWinnerImpossibleDueToTooFewDisputersError, TeamDoesNotExistsError, TeamOfSignerAlreadyParticipatesInDisputeError, TimeElapsedToJoinTeamError, TimeElapsedForDisputeParticipationError,
    TimeElapsedToClaimVictoryError, TimeElapsedToUnclaimVictoryError, UnclaimVictoryNotAuthorized, WinnerNotRevealedYetError, WithdrawPoolByLooserTeamImpossibleError, WithdrawPoolNotAuthorized} from "../src/BitarenaChallengeErrors.sol";


contract BitarenaTest is Test {
    BitarenaFactory public bitarenaFactory;
    address ADMIN_FACTORY = makeAddr("adminFactory");
    address ADMIN_CHALLENGE1 = makeAddr("adminChallenge1");
    address ADMIN_CHALLENGE2 = makeAddr("adminChallenge2");
    address ADMIN_DISPUTE_CHALLENGE1 = makeAddr("adminDisputeChallenge1");
    address ADMIN_DISPUTE_CHALLENGE2 = makeAddr("adminDisputeChallenge2");
    address CREATOR_CHALLENGE1 = makeAddr("creatorChallenge1");
    address CREATOR_CHALLENGE2 = makeAddr("creatorChallenge2");
    address PLAYER1_CHALLENGE1 = makeAddr("player1Challenge1");
    address PLAYER2_CHALLENGE1 = makeAddr("player2Challenge1");
    address PLAYER3_CHALLENGE1 = makeAddr("player3Challenge1");
    address PLAYER4_CHALLENGE1 = makeAddr("player4Challenge1");
    address PLAYER_WITH_NOT_SUFFICIENT_BALANCE = makeAddr("playerWithBalanceZero");

    bytes32 CHALLENGE1 = "Challenge 1";
    bytes32 CHALLENGE2 = "Challenge 2";
    bytes32 GAME1 = "Counter Strike";
    bytes32 GAME2 = "Far cry";
    bytes32 PLATFORM1 = "UOS";
    bytes32 PLATFORM2 = "Steam";
    uint16 ONE_TEAM = 1;
    uint16 TWO_TEAMS = 2;
    uint16 ONE_PLAYER = 1;
    uint16 TWO_PLAYERS = 2;
    uint16 THREE_PLAYERS = 3;
    uint AMOUNT_PER_PLAYER = 1 ether;
    uint AMOUNT_NOT_SUFFICIENT = 1000 gwei;


    uint256 private constant STARTING_BALANCE_ETH = 10 ether; 
    uint256 private constant STARTING_BALANCE_NOT_SUFFICIENT_ETH = 5000 gwei; 

    function setUp() public {
        //BitarenaToken bitarenaToken = new BitarenaToken();

        vm.deal(CREATOR_CHALLENGE1, STARTING_BALANCE_ETH);
        vm.deal(CREATOR_CHALLENGE2, STARTING_BALANCE_ETH);
        vm.deal(PLAYER1_CHALLENGE1, STARTING_BALANCE_ETH);
        vm.deal(PLAYER2_CHALLENGE1, STARTING_BALANCE_ETH);
        vm.deal(PLAYER3_CHALLENGE1, STARTING_BALANCE_ETH);
        vm.deal(PLAYER_WITH_NOT_SUFFICIENT_BALANCE, STARTING_BALANCE_NOT_SUFFICIENT_ETH);

    }

    function deployFactory() public {
        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory = new BitarenaFactory();
        vm.stopBroadcast();
        vm.deal(address(bitarenaFactory), STARTING_BALANCE_ETH);
    }

    /**
     * Intent creation of a challenge with 2 teams & 1 player per team. The challenge is set to begin 1 day later
     */
    function intentChallengeCreationWith2TeamsAnd1Player() public {
        deployFactory();
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: AMOUNT_PER_PLAYER}(
            CHALLENGE1,
            GAME1,
            PLATFORM1,
            TWO_TEAMS,
            ONE_PLAYER,
            AMOUNT_PER_PLAYER,
            block.timestamp + 1 days,
            false
        );
        vm.stopBroadcast();
    }

    /**
     * Create a challenge with 2 teams & 2 players. The challenge is set to begin 1 day later
     */
    function createChallengeWith2TeamsAnd2Players() public returns(BitarenaChallenge) {
        deployFactory();
        
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: AMOUNT_PER_PLAYER}(
            CHALLENGE1,
            GAME1,
            PLATFORM1,
            TWO_TEAMS,
            TWO_PLAYERS,
            AMOUNT_PER_PLAYER,
            block.timestamp + 1 days,
            false
        );
        vm.stopBroadcast();

        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        return bitarenaChallenge;
    }

    /**
     * @dev
     */
    function joinTeamWith2PlayersPerTeam(BitarenaChallenge bitarenaChallenge) private {
        //send players some native tokens to enable them to jointeams
        //A second player joins the team 1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               


        //The PLAYER2 creates a new team : team with index 2 is created
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               

        //The PLAYER3 joins the team2 (with index 2) 
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(2);
        vm.stopBroadcast();         

    }
    

    /**
     * @dev Test revert with "ChallengeNameError" when no name is provided for challenge
     */
    function testIntentChallengeCreationError1() public {
        deployFactory();
        vm.expectRevert(ChallengeNameError.selector);
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: AMOUNT_PER_PLAYER}(
            '',
            GAME1,
            PLATFORM1,
            TWO_TEAMS,
            ONE_PLAYER,
            AMOUNT_PER_PLAYER,
            block.timestamp + 10 hours,
            false
        );
        vm.stopBroadcast();
    }

    /**
     * @dev Test revert with "ChallengeGameError" when no game is provided for challenge
     */
    function testIntentChallengeCreationError2() public {
        deployFactory();
        vm.expectRevert(ChallengeGameError.selector);
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: AMOUNT_PER_PLAYER}(
            CHALLENGE1,
            '',
            PLATFORM1,
            TWO_TEAMS,
            ONE_PLAYER,
            AMOUNT_PER_PLAYER,
            block.timestamp + 10 hours,
            false
        );
        vm.stopBroadcast();
    }

    /**
     * @dev Test revert with "ChallengePlatformError" when no platform is provided for challenge
     */
    function testIntentChallengeCreationError3() public {
        deployFactory();
        vm.expectRevert(ChallengePlatformError.selector);
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: AMOUNT_PER_PLAYER}(
            CHALLENGE1,
            GAME1,
            '',
            TWO_TEAMS,
            ONE_PLAYER,
            AMOUNT_PER_PLAYER,
            block.timestamp + 10 hours,
            false
        );
        vm.stopBroadcast();
    }

    /**
     * @dev Test revert with "NbTeamsError" when an incorrect value for number of teams is provided
     */
    function testIntentChallengeCreationError4() public {
        deployFactory();
        vm.expectRevert(NbTeamsError.selector);
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: AMOUNT_PER_PLAYER}(
            CHALLENGE1,
            GAME1,
            PLATFORM1,
            1,
            ONE_PLAYER,
            AMOUNT_PER_PLAYER,
            block.timestamp + 10 hours,
            false
        );
        vm.stopBroadcast();
    }

    /**
     * @dev Test revert with "NbPlayersPerTeamsError" when an incorrect value for number of players per teams is provided
     */
    function testIntentChallengeCreationError5() public {
        deployFactory();
        vm.expectRevert(NbPlayersPerTeamsError.selector);
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: AMOUNT_PER_PLAYER}(
            CHALLENGE1,
            GAME1,
            PLATFORM1,
            TWO_TEAMS,
            0,
            AMOUNT_PER_PLAYER,
            block.timestamp + 10 hours,
            false
        );
        vm.stopBroadcast();
    }

    /**
     * @dev Test revert with "ChallengeStartDateError" when an incorrect value for start date of challenge is provided
     */
    function testIntentChallengeCreationError6() public {
        deployFactory();
        vm.expectRevert(ChallengeStartDateError.selector);
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: AMOUNT_PER_PLAYER}(
            CHALLENGE1,
            GAME1,
            PLATFORM1,
            TWO_TEAMS,
            ONE_PLAYER,
            AMOUNT_PER_PLAYER,
            block.timestamp,
            false
        );
        vm.stopBroadcast();
    }

    /**
     * @dev Test revert with "BalanceChallengeCreatorError" when the balance of the creator is too low
     */
    function testIntentChallengeCreationError7() public {
        deployFactory();
        vm.expectRevert(BalanceChallengeCreatorError.selector);
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: 1000 gwei}(
            CHALLENGE1,
            GAME1,
            PLATFORM1,
            TWO_TEAMS,
            ONE_PLAYER,
            AMOUNT_PER_PLAYER,
            block.timestamp + 1 days,
            false
        );
        vm.stopBroadcast();
    }

    /**
     * @dev Test value of challenge counter after 1 intent creation. The counter must be equal to 1
     */
    function testCounterChallengeAfterIntentChallengeCreation() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        assertEq(bitarenaFactory.getChallengeCounter(), 1);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation1() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 
        assertEq(challengeStructCreated.challengeName, CHALLENGE1);
    }
    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation2() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 
        assertEq(challengeStructCreated.game, GAME1);
    }

    /**
     * @dev Test value of state var "s_game" after challenge creation/deployment
     */
    function testStateVariableAfterChallengeDeployment2() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getGame(), GAME1);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation3() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 
        assertEq(challengeStructCreated.platform, PLATFORM1);
    }

    /**
     * @dev Test value of mapping state var "s_platform" after challenge creation/deployment 
     */
    function testStateVariableAfterChallengeDeployment3() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getPlatform(), PLATFORM1);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation4() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 
        assertEq(challengeStructCreated.nbTeams, TWO_TEAMS);
    }

    /**
     * @dev Test value of state var "s_nbTeams" after challenge creation/deployment 
     */
    function testStateVariableAfterChallengeDeployment4() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getNbTeams(), TWO_TEAMS);
    }

    /**
     * @dev Test value of state var "s_disputeAdmin" after challenge creation/deployment 
     */
    function testStateVariableAfterChallengeDeployment5() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getDisputeAdmin(), ADMIN_DISPUTE_CHALLENGE1);
    }

    /**
     * @dev Test value of state var "s_disputeAdmin" after challenge creation/deployment 
     */
    function testStateVariableAfterChallengeDeployment6() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getChallengeAdmin(), ADMIN_CHALLENGE1);
    }

    /**
     * @dev Test value of state var "s_feePercentage" after challenge creation/deployment 
     */
    function testStateVariableAfterChallengeDeployment7() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getFeePercentage(), FEE_PERCENTAGE_AMOUNT_BY_DEFAULT);
    }

    /**
     * @dev Test value of state var "s_feePercentage" after challenge creation/deployment and set a new fee
     */
    function testStateVariableAfterChallengeDeployment8() public {
        uint16 newFee = 12;
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getFeePercentage(), FEE_PERCENTAGE_AMOUNT_BY_DEFAULT);

        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setFeePercentage(newFee);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getFeePercentage(), newFee);
    }

    /**
     * @dev Test getter "getNbTeamPlayers"
     * We create a challenge with 1 player per team so we expect that the getter returns 1
     */
    function testGetterAfterChallengeDeployment1() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        //We create a challenge with 1 player per team so we expect that the getter returns 1
        assertEq(bitarenaChallenge.getNbTeamPlayers(), 1);

    }

    /**
     * @dev Test getter "getNbTeamPlayers"
     * We create a challenge with 2 players per team so we expect that the getter returns 2
     */
    function testGetterAfterChallengeDeployment2() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        assertEq(bitarenaChallenge.getNbTeamPlayers(), 2);
    }

    /**
     * @dev Test getter "getChallengeStartDate"
     */
    function testGetterAfterChallengeDeployment3() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        assertEq(bitarenaChallenge.getChallengeStartDate(), block.timestamp + 1 days);
    }

    /**
     * @dev Test getter "getChallengeVisibility"
     * We expect value "false" as the function "createChallengeWith2TeamsAnd2Players" is built 
     * with is_private =false 
     */
    function testGetterAfterChallengeDeployment4() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        assertEq(bitarenaChallenge.getChallengeVisibility(), false);
    }

    /**
     * @dev Test getter "getIsCanceled"
     * We expect value "false" just after challenge deployment
     * 
     */
    function testGetterAfterChallengeDeployment5() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        assertEq(bitarenaChallenge.getIsCanceled(), false);
    }
    /**
     * @dev Test getter "getIsCanceled"
     * We expect value "false" after canceling the challenge by the creator
     * 
     */
    function testGetterAfterChallengeDeployment6() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaChallenge.cancelChallenge();
        vm.stopBroadcast();
        assertEq(bitarenaChallenge.getIsCanceled(), true);
    }

    /**
     * @dev Test getter "getTeamOfPlayer"
     * 
     */
    function testGetterAfterChallengeDeployment7() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);
        assertEq(bitarenaChallenge.getTeamOfPlayer(CREATOR_CHALLENGE1), 1);
        assertEq(bitarenaChallenge.getTeamOfPlayer(PLAYER2_CHALLENGE1), 2);
    }
    
    /**
     * @dev Test getter "getDelayStartVictoryClaim"
     * 
     */
    function testGetterAfterChallengeDeployment8() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(1 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(10 hours);
        vm.stopBroadcast();
        assertEq(bitarenaChallenge.getDelayStartVictoryClaim(), 1 hours);
        assertEq(bitarenaChallenge.getDelayEndVictoryClaim(), 10 hours);

    }
    /**
     * @dev Test getter "getDelayEndVictoryClaim"
     * 
     */
    function testGetterAfterChallengeDeployment9() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(5 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();
        console.log('DELAY 2', bitarenaChallenge.getDelayEndVictoryClaim());
        assertEq(bitarenaChallenge.getDelayStartVictoryClaim(), 5 hours);
        assertEq(bitarenaChallenge.getDelayEndVictoryClaim(), 20 hours);
    }

    /**
     * @dev Test setter "setDelayStartVictoryClaim"
     * 
     */
    function testSetterAfterChallengeDeployment1() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        vm.stopBroadcast();

        vm.expectRevert(DelayStartClaimVictoryGreaterThanDelayEndClaimVictoryError.selector);
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayEndForVictoryClaim(5 hours);
        vm.stopBroadcast();
    }

    /**
     * @dev Test getter "getDisputePool"
     * 
     */
    function testGetterAfterChallengeDeployment10() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);
        
        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //There is a dispute so 1 member of a team participate in a dispute
        uint256 amountDisputePerPlayer = bitarenaChallenge.getDisputeAmountParticipation();
        vm.warp(bitarenaChallenge.getChallengeStartDate() + bitarenaChallenge.getDelayStartVictoryClaim() + bitarenaChallenge.getDelayEndVictoryClaim() + 1 hours);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value : amountDisputePerPlayer}();
        vm.stopBroadcast();         

        vm.warp(bitarenaChallenge.getChallengeStartDate() + bitarenaChallenge.getDelayStartVictoryClaim() + bitarenaChallenge.getDelayEndVictoryClaim() + 2 hours);
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value : amountDisputePerPlayer}();
        vm.stopBroadcast();         

        assertEq(bitarenaChallenge.getDisputePool(), 2 * amountDisputePerPlayer);

    }

    /**
     * @dev Test roles after challenge creation/deployment 
     */
    function testRolesAfterChallengeDeployment1() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.hasRole(CHALLENGE_ADMIN_ROLE, ADMIN_CHALLENGE1), true);
        assertEq(bitarenaChallenge.hasRole(CHALLENGE_DISPUTE_ADMIN_ROLE, ADMIN_DISPUTE_CHALLENGE1), true);
        assertEq(bitarenaChallenge.hasRole(CHALLENGE_CREATOR_ROLE, CREATOR_CHALLENGE1), true);
    }



    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation5() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 
        assertEq(challengeStructCreated.nbTeamPlayers, ONE_PLAYER);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation6() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 
        assertEq(challengeStructCreated.amountPerPlayer, AMOUNT_PER_PLAYER);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation7() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 
        assertEq(challengeStructCreated.startAt, block.timestamp + 1 days);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation8() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 
        assertEq(challengeStructCreated.isPrivate, false);
    }

    /**
     * @dev Test balance of Factory smart contract after intent challenge creation 
     */
    function testBalanceFactoryAfterIntentChallengeCreation8() public {
        intentChallengeCreationWith2TeamsAnd1Player();        
        assertEq(address(bitarenaFactory).balance, AMOUNT_PER_PLAYER+STARTING_BALANCE_ETH);
    }

    /**
     * @dev Test challenge pool after challenge deployment.
     * YThe value of the state var s_challengePoolafter deployment must be equal to 's_amountPerPlayer'
     */
    function testChallengePoolAfterChallengeDeployment() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        
        assertEq(bitarenaChallenge.getChallengePool(), bitarenaChallenge.getAmountPerPlayer());
        assertEq(bitarenaChallenge.getChallengePool(), address(bitarenaChallenge).balance);
    }

    /**
     * @dev Test balance of challenge creator after intent challenge creation 
     */
    function testBalanceCreatorAfterIntentChallengeCreation8() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        assertEq(address(CREATOR_CHALLENGE1).balance, STARTING_BALANCE_ETH - AMOUNT_PER_PLAYER);
    }

    /**
     * @dev Test challenge creation fails if a bad index is provided (= not exists )
     */
    function testChallengeCreationRevertIfBadCounterIsProvided() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.expectRevert(ChallengeCounterError.selector);
        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 2);
        vm.stopBroadcast();       
    }

    /**
     * @dev Test balance factory before deploying a challenge
     * The factory owns 'STARTING_BALANCE_ETH' before the challenge intent creation
     * After the Challenge intent creation it must own 'STARTING_BALANCE_ETH' + AMOUNT_PER_PLAYER
     */
    function testBalanceFactoryBeforeDeployingChallenge() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        // BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        // console.log('BALANCE OF FACTORY AFTER ', address(bitarenaFactory).balance);
        vm.stopBroadcast();       
        assertEq(address(bitarenaFactory).balance, STARTING_BALANCE_ETH + AMOUNT_PER_PLAYER);
    }

    /**
     * @dev Test balance factory after deploying a challenge
     * The factory owns 'STARTING_BALANCE_ETH' before the challenge deployment 
     * And after the deployment it owns 'STARTING_BALANCE_ETH' as well
     */
    function testBalanceFactoryAfterDeployingChallenge() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(address(bitarenaFactory).balance, STARTING_BALANCE_ETH);
    }

    /**
     * @dev Test that the property 'challengeAddress' is correctly hydrated after Challenge Deployment
     * 
     */
    function testChallengeAddressInStateVariableStructAfterDeploying() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaFactory.isChallengeDeployed(1), true);
    }

    /**
     * @dev Test that the property 'challengeAddress' is equal to address(0) before Challenge deployment
     * 
     */
    function testChallengeAddressInStateVariableStructBeforeDeploying() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        assertEq(bitarenaFactory.isChallengeDeployed(1), false);
    }

    /**
     * @dev Test that the first team is created after Challenge deployment
     * 
     */
    function testFirstTeamCreatedAfterChallengeDeployment() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getTeamCounter(), 1);
    }

    /**
     * @dev Test that the only player in the first team after Challenge deployment is the challenge creator
     * 
     */
    function testFirstTeamCreatedAfterChallengeDeploymentContainsOnlyCreator() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       
        
        assertEq(bitarenaChallenge.getTeamsByTeamIndex(1)[0], bitarenaChallenge.getCreator());
    }

    /**
     * @dev Test that if the Challenge is set with only 1 player per team, anyone can join the team created by the creator 
     * as it's the unique player in his team
     * 
     */
    function testPlayerCanNotJoinTeamIfCreatorCreateChallengeWithOnlyOnePlayerPerTeam() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        vm.expectRevert(NbPlayersPerTeamsLimitReachedError.selector);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               
    }

    /**
     * @dev Test that a player can create a team if nb teams limit is OK
     * as it's the unique player in his team
     * Case of challenge that is set with 2 teams and only 1 player per team
     */
    function testPlayerCanCreateTeamIfNbTeamsLimitIsOk() public {
        intentChallengeCreationWith2TeamsAnd1Player();
        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_DISPUTE_CHALLENGE1, 1);
        vm.stopBroadcast();       

        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               

        //Test that data are OK : 
        //teamCounter = 2
        //creator is the only player in the team 1
        //PLAYER1_CHALLENGE1 is the only player in the team 2
        assertEq(bitarenaChallenge.getTeamCounter(), 2);
        assertEq(bitarenaChallenge.getTeamsByTeamIndex(1)[0], bitarenaChallenge.getCreator());
        assertEq(bitarenaChallenge.getTeamsByTeamIndex(2)[0], PLAYER1_CHALLENGE1);
        assertEq(bitarenaChallenge.getTeamsByTeamIndex(1).length, 1);
        assertEq(bitarenaChallenge.getTeamsByTeamIndex(2).length, 1);
    }

    /**
     * @dev Test that some players can join teams if limits are ok
     * Case of challenge that is set with 2 teams and 2 players per team
     */
    function testPlayersCanJoinExistingTeamsIfLimitIsOk() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        
        //send players some native tokens to enable them to jointeams
        //A second player joins the team 1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               


        //The PLAYER2 creates a new team : team with index 2 is created
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               

        //The PLAYER3 joins the team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(2);
        vm.stopBroadcast();               

        //Test that data are OK : 
        //teamCounter = 2
        //creator and PLAYER1 are players of team 1
        //PLAYER2 and PLAYER3 are players of team 2
        assertEq(bitarenaChallenge.getTeamCounter(), 2);
        assertEq(bitarenaChallenge.getTeamsByTeamIndex(1)[0], bitarenaChallenge.getCreator());
        assertEq(bitarenaChallenge.getTeamsByTeamIndex(1)[1], PLAYER1_CHALLENGE1);
        assertEq(bitarenaChallenge.getTeamsByTeamIndex(2)[0], PLAYER2_CHALLENGE1);
        assertEq(bitarenaChallenge.getTeamsByTeamIndex(2)[1], PLAYER3_CHALLENGE1);
    }

    /**
     * @dev Test that a player wirth balance zero or not enougn tokens cannot jon existing team
     */
    function testPlayersWithNullBalanceCanNotJoinExistingTeam() public {

        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        //send players some native tokens to enable them to jointeams
        //A second player joins the team 1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               


        //The PLAYER2 creates a new team : team with index 2 is created
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               

        //The PLAYER_WITH_BALANCE_ZERO wants to join the team2
        vm.expectRevert(BalanceChallengePlayerError.selector);
        vm.startBroadcast(PLAYER_WITH_NOT_SUFFICIENT_BALANCE);
        bitarenaChallenge.createOrJoinTeam{value: 0}(2);
        vm.stopBroadcast();               

    }

    /**
     * @dev Test that the challenge pool is correct after manyplayers join different teams
     * Case of challenge that is set with 2 teams and 2 players per team. 
     * So the challenge pool must be equal to 4 x s_amountPerPlayer
     */
    function testChallengePoolAfterPlayersJoinTeams() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();

        //send players some native tokens to enable them to jointeams
        //A second player joins the team 1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               


        //The PLAYER2 creates a new team : team with index 2 is created
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               

        //The PLAYER3 joins the team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(2);
        vm.stopBroadcast();               

        assertEq(bitarenaChallenge.getChallengePool(), 4 * bitarenaChallenge.getAmountPerPlayer());
        assertEq(bitarenaChallenge.getChallengePool(), address(bitarenaChallenge).balance);
    }

    /**
     * @dev Test that some players can not join team after challenge start date
     */
    function testPlayersCanNotJoinExistingTeamsAfterChallengeStartDate() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();

        //send players some native tokens to enable them to jointeams
        //A second player joins the team 1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               


        //The PLAYER2 creates a new team : team with index 2 is created
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               

        //The PLAYER3 joins the team2 2 days leter (we define the startAt 1 day in the future)
        uint256 TwoDaysInTheFuture = block.timestamp + 2 days;
        vm.warp(TwoDaysInTheFuture);
        vm.expectRevert(TimeElapsedToJoinTeamError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(2);
        vm.stopBroadcast();               
    }

    /**
     * @dev Test that some players can not join team that does not exist 
     */
    function testPlayersCanNotJoinNotExistingTeam() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();

        //send players some native tokens to enable them to jointeams
        //A second player joins the team 1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               


        //The PLAYER2 creates a new team : team with index 2 is created
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               

        //The PLAYER3 joins the team3 (with index 3) that does not exist
        vm.expectRevert(TeamDoesNotExistsError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(3);
        vm.stopBroadcast();               
    }

    /**
     * @dev Test that native tokens are sent back to players that join team after the creator cancel the challenge
     */
    function testCancelChallenge1() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();

        uint256 balanceCreatorAfterJoiningTeam = CREATOR_CHALLENGE1.balance;

        //A second player joins the team 1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               
        uint256 balancePlayer1AfterJoiningTeam = PLAYER1_CHALLENGE1.balance;
        
        //The PLAYER2 creates a new team : team with index 2 is created
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               
        uint256 balancePlayer2AfterJoiningTeam = PLAYER2_CHALLENGE1.balance;

        //The PLAYER3 joins the team2 (with index 2) 
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(2);
        vm.stopBroadcast();               
        uint256 balancePlayer3AfterJoiningTeam = PLAYER3_CHALLENGE1.balance;

        uint256 balanceSmartContractChallengeAfterAllPlayersJoinTeams = address(bitarenaChallenge).balance;
        console.log('balanceSmartContractChallengeAfterAllPlayersJoinTeams : ', balanceSmartContractChallengeAfterAllPlayersJoinTeams);

        //The creator cancels the challenge
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaChallenge.cancelChallenge();
        vm.stopBroadcast();

        uint256 balancePlayer1AfterChallengeCancel = PLAYER1_CHALLENGE1.balance;
        uint256 balancePlayer2AfterChallengeCancel = PLAYER2_CHALLENGE1.balance;
        uint256 balancePlayer3AfterChallengeCancel = PLAYER3_CHALLENGE1.balance;
        uint256 balanceCreatorAfterChallengeCancel = CREATOR_CHALLENGE1.balance;
        uint256 balanceSmartContractChallengeChallengeCancel = address(bitarenaChallenge).balance;
        console.log('balanceSmartContractChallengeChallengeCancel : ', balanceSmartContractChallengeChallengeCancel);

        //Every player is sent back with 'AMOUNT_PER_PLAYER'
        assertEq(balancePlayer1AfterChallengeCancel, balancePlayer1AfterJoiningTeam + AMOUNT_PER_PLAYER);
        assertEq(balancePlayer2AfterChallengeCancel, balancePlayer2AfterJoiningTeam + AMOUNT_PER_PLAYER);
        assertEq(balancePlayer3AfterChallengeCancel, balancePlayer3AfterJoiningTeam + AMOUNT_PER_PLAYER);
        assertEq(balanceCreatorAfterChallengeCancel, balanceCreatorAfterJoiningTeam + AMOUNT_PER_PLAYER);
        //The smart contract sent back 4 times AMOUNT_PER_PLAYER because there are 4 players and its balance decreased with that amount
        assertEq(balanceSmartContractChallengeChallengeCancel, balanceSmartContractChallengeAfterAllPlayersJoinTeams - (4 *AMOUNT_PER_PLAYER));
    }   


    /**
     * @dev Test that it's impossible to join a team after a challenge was cancelled by the creator
     */
    function testCancelChallenge2() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();

        //The creator cancels the challenge
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaChallenge.cancelChallenge();
        vm.stopBroadcast();

        //A second player joins the team 1
        vm.expectRevert(ChallengeCanceledError.selector);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               
    }   

    /**
     * @dev Test that it's impossible to cancel the challenge after start date of the challenge
     */
    function testCancelChallenge3() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();

        //The creator cancels the challenge in 2 days so after the start date of the challenge
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(ChallengeCancelAfterStartDateError.selector);
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaChallenge.cancelChallenge();
        vm.stopBroadcast();
    }   

    /********  TESTS ON CLAIM VICTORY ***************/
    /**
     * @dev Test that it's possible to claim victory if the claiming period is ok
     */
    function testClaimVictory1() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to claim 15 hours after the start date
        // And the victory claim must succeeds !
        uint256 _1Day15HoursInTheFuture = block.timestamp + 1 days + 15 hours;
        vm.warp(_1Day15HoursInTheFuture);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         
    }   

    /**
     * @dev Test that it's impossible to claim victory after the claiming period
     * It reverts with error "TimeElapsedToClaimVictoryError"
     */
    function testClaimVictory2() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to claim 3 days after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 3 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(TimeElapsedToClaimVictoryError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         
    }   

    /**
     * @dev Test that it's impossible to claim victory if at least one delay to claim it is not set
     */
    function testClaimVictory3() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayStartForVictoryClaim(0);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to claim 3 days after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 3 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(DelayClaimVictoryNotSet.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         
    }   

    /**
     * @dev Test that it's impossible to claim victory after the legal delay
     */
    function testClaimVictory4() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(0);
        bitarenaChallenge.setDelayEndForVictoryClaim(10 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to claim 15 hours after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 3 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(DelayClaimVictoryNotSet.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         
    }   

    /**
     * @dev Test that it's impossible to claim victory if a player claim victory for a team that does not exist
     */
    function testClaimVictory5() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to claim 15 hours after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 3 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(TeamDoesNotExistsError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(3);
        vm.stopBroadcast();         
    }   

    /** @dev Test that it's impossible to claim victory if a challenge is canceled
     * 
     */
    function testClaimVictory6() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaChallenge.cancelChallenge();
        vm.stopBroadcast();               

        //As the challenge must start 1 day after its creation, we try to claim 2 days after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(ChallengeCanceledError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         
    }   

    /** 
     * @dev Test that it's impossible to claim victory if a player is not authorized (=bad role)
     */
    function testClaimVictory7() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER4 tries to claim the victory but he's not authorized as he has not the GAMER_ROLE
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(ClaimVictoryNotAuthorized.selector);
        vm.startBroadcast(PLAYER4_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         
    }   

    /** 
     * @dev Test that it's impossible to claim victory for a team that is not yours
     */
    function testClaimVictory8() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 that is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(NotTeamMemberError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         
    }   

    /********  TESTS ON UNCLAIM VICTORY ***************/
    /**
     * @dev Test that it's possible to unclaim victory if the claiming period is ok
     */
    function testUnclaimVictory1() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to claim 15 hours after the start date
        // And the victory claim must succeeds !
        uint256 _1Day15HoursInTheFuture = block.timestamp + 1 days + 15 hours;
        vm.warp(_1Day15HoursInTheFuture);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(2);
        vm.stopBroadcast();         
    }   

    /**
     * @dev Test that it's impossible to claim victory after the claiming period
     * It reverts with error "TimeElapsedToClaimVictoryError"
     */
    function testUnclaimVictory2() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory unclaim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to claim 3 days after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 3 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(TimeElapsedToUnclaimVictoryError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(2);
        vm.stopBroadcast();         
    }   

    /**
     * @dev Test that it's impossible to unclaim victory if at least one delay to claim it is not set
     */
    function testUnclaimVictory3() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(0);
        vm.stopBroadcast();         

        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayEndForVictoryClaim(10 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to unclaim 3 days after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 3 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(DelayUnclaimVictoryNotSet.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(2);
        vm.stopBroadcast();         
    }   

    /**
     * @dev Test that it's impossible to unclaim victory after the legal delay
     */
    function testUnclaimVictory4() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory unclaim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(1 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to claim 3 days after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 3 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(TimeElapsedToUnclaimVictoryError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(2);
        vm.stopBroadcast();         
    }   

    /**
     * @dev Test that it's impossible to unclaim victory if a player unclaim victory for a team that does not exist
     */
    function testUnclaimVictory5() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory unclaim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, we try to unclaim 15 hours after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 3 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(TeamDoesNotExistsError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(3);
        vm.stopBroadcast();         
    }   

    /** @dev Test that it's impossible to unclaim victory if a challenge is canceled
     * 
     */
    function testUnclaimVictory6() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaChallenge.cancelChallenge();
        vm.stopBroadcast();               

        //As the challenge must start 1 day after its creation, we try to claim 2 days after the start date
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(ChallengeCanceledError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(2);
        vm.stopBroadcast();         
    }   

    /** 
     * @dev Test that it's impossible to unclaim victory if a player is not authorized (=bad role)
     */
    function testUnclaimVictory7() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER4 tries to claim the victory but he's not authorized as he has not the GAMER_ROLE
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(UnclaimVictoryNotAuthorized.selector);
        vm.startBroadcast(PLAYER4_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(2);
        vm.stopBroadcast();         
    }   

    /** 
     * @dev Test that it's impossible to unclaim victory for a team that is not yours
     */
    function testUclaimVictory8() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to unclaim the victory for the team1 that is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);
        vm.expectRevert(NotTeamMemberError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(1);
        vm.stopBroadcast();         
    }   

    /********  TESTS ON DISPUTE ***************/
    /** 
     * @dev Test that if two teams claim their victory, there is a dispute
     */
    function testDispute1() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        assertEq(bitarenaChallenge.atLeast2TeamsClaimVictory(), true);
    }   

    /** 
     * @dev Test that with 2 teams if one team claim its victory and the second do not, there is no dispute
     */
    function testDispute2() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        assertEq(bitarenaChallenge.atLeast2TeamsClaimVictory(), false);
    }   

     /** 
     * @dev Test that state var s_feeDispute is OK after the admin sets it 
     */
    function testDispute3() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //ADMIN_CHALLENGE1 sets fee dispute after that
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setFeePercentageDispute(10);
        vm.stopBroadcast();         

        assertEq(bitarenaChallenge.getFeePercentageDispute(), 10);
    }   

     /** 
     * @dev Test that state only ADMIN_CHALLENGE can set the fee for dispute
     */
    function testDispute4() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER1_CHALLENGE1 sets fee dispute but it reverts with AccessControl error
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, PLAYER1_CHALLENGE1, CHALLENGE_ADMIN_ROLE));
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.setFeePercentageDispute(10);
        vm.stopBroadcast();         

    }   

    /** 
     * @dev Test that if 2 teams claim their victory and the second finnaly unclaims victory, there is no dispute
     */
    function testDispute5() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //PLAYER1 finally unclaims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(1);
        vm.stopBroadcast();         

        assertEq(bitarenaChallenge.atLeast2TeamsClaimVictory(), false);
    }   

    /** 
     * @dev Test that if there is no dispute anyone can particpate to a dispute
     */
    function testDispute6() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //PLAYER1 finally unclaims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.unclaimVictory(1);
        vm.stopBroadcast();         

        //The ADMIN set the fee for the dispute

        //There is no dispute so anyone can participate to a dispute
        //PLAYER1 wants to participete to a dispute 
        vm.expectRevert(NoDisputeError.selector);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: 1 ether}();
        vm.stopBroadcast();         
    }   

    /** 
     * @dev Test that if there a dispute, a dispute participation is possible
     */
    function testDispute7() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //There is a dispute so anyone can participate to a dispute
        //PLAYER1 wants to participate to a dispute after a correct delay        
        vm.warp(bitarenaChallenge.getChallengeStartDate() + bitarenaChallenge.getDelayStartVictoryClaim() + bitarenaChallenge.getDelayEndVictoryClaim() + 1 hours);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: bitarenaChallenge.getDisputeAmountParticipation()}();
        vm.stopBroadcast();         

        assertEq(true, true);
    }   

    /** 
     * @dev Test that if there a dispute, the tx revertsif the fee result set by the admin equals 0
     */
    function testDispute8() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //ADMIN_CHALLENGE set fee dispute to 0
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setFeePercentageDispute(0);
        vm.stopBroadcast();         

        //There is a dispute so anyone can participate to a dispute
        //PLAYER1 wants to participate to a dispute         
        vm.expectRevert(FeeDisputeNotSetError.selector);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: 1 ether}();
        vm.stopBroadcast();         

        assertEq(true, true);
    }   

    /** 
     * @dev Test that if there a dispute, the tx reverts if the fee result set by the admin equals 0
     */
    function testDispute9() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //ADMIN_CHALLENGE set fee dispute to 0
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setFeePercentageDispute(0);
        vm.stopBroadcast();         

        //There is a dispute so anyone can participate to a dispute
        //PLAYER1 wants to participate to a dispute         
        vm.expectRevert(FeeDisputeNotSetError.selector);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: 1 ether}();
        vm.stopBroadcast();         

        assertEq(true, true);
    }   

    /** 
     * @dev Test that if there a dispute, you must be authorized to participâte to a dispute
     * if the amount is not sufficient
     */
    function testDispute10() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //There is a dispute so anyone who is granted can participate to a dispute
        //PLAYER4 wants to participate to a dispute but he did not participate to the challenge
        vm.deal(PLAYER4_CHALLENGE1, 1 ether);
        vm.expectRevert(DisputeParticipationNotAuthorizedError.selector);
        vm.startBroadcast(PLAYER4_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: 1 ether}();
        vm.stopBroadcast();         

        assertEq(true, true);
    }   

    /** 
     * @dev Test that if there a dispute, you must pay at least the amount for particpation otherwise the tx fails
     * if the amount is not sufficient
     */
    function testDispute11() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //There is a dispute so anyone who is granted can participate to a dispute
        //PLAYER3 wants to participate to a dispute but he provides a not sufficient amount 
        vm.expectRevert(NotSufficientAmountForDisputeError.selector);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        //uint256 amountDispute = bitarenaChallenge.getDisputeAmountParticipation() - 1000;
        bitarenaChallenge.participateToDispute{value: 1000}();
        vm.stopBroadcast();         

        assertEq(true, true);
    }   

    /** 
    * @dev Test different dispute participations cases 
    * 
    */
    function testDispute12() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //ADMIN of the CHALLENGE wants to refund Dispute amount but it fails because there is no dispute participants
        vm.expectRevert(NoDisputeParticipantsError.selector);
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.refundDisputeAmount();
        vm.stopBroadcast();         

        //There is a dispute so PLAYER3 wants to participate to a dispute after the claim victory 
        vm.warp(bitarenaChallenge.getChallengeStartDate() + bitarenaChallenge.getDelayStartVictoryClaim() + bitarenaChallenge.getDelayEndVictoryClaim() + 1 hours);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        uint256 amountDispute = bitarenaChallenge.getDisputeAmountParticipation();
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         


        assertEq(bitarenaChallenge.getDisputeParticipants(2), PLAYER3_CHALLENGE1);
        assertEq(bitarenaChallenge.getDisputeParticipantsCount(), 1);
        
        //PLAYER1 wants to participate to a dispute as well
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         

        assertEq(bitarenaChallenge.getDisputeParticipants(1), PLAYER1_CHALLENGE1);
        assertEq(bitarenaChallenge.getDisputeParticipantsCount(), 2);

        //PLAYER2 (=team2) wants to participate to a dispute but PLAYER3 from the same team did it
        //So it must revert with error 'TeamOfSignerAlreadyParticipatesInDisputeError'
        vm.expectRevert(TeamOfSignerAlreadyParticipatesInDisputeError.selector);
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         

        //ADMIN of the CHALLENGE wants to refund dispute amount but it fails because there 2 disputers and 
        // the refund is possible if there is only 1 disputer
        vm.expectRevert(RefundImpossibleDueToTooManyDisputeParticipantsError.selector);
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.refundDisputeAmount();
        vm.stopBroadcast();         

    }   

    /** 
    * @dev Test that if there is only 1 disputer, the admin can refund 
    * 
    */
    function testDispute13() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 that is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //ADMIN of the CHALLENGE wants to refund Dispute amount but it fails because there is no dispute participants
        vm.expectRevert(NoDisputeParticipantsError.selector);
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.refundDisputeAmount();
        vm.stopBroadcast();         

        //There is a dispute so PLAYER3 wants to participate to a dispute 
        vm.warp(bitarenaChallenge.getChallengeStartDate() + bitarenaChallenge.getDelayStartVictoryClaim() + bitarenaChallenge.getDelayEndVictoryClaim() + 1 hours);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        uint256 amountDispute = bitarenaChallenge.getDisputeAmountParticipation();
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         


        assertEq(bitarenaChallenge.getDisputeParticipants(2), PLAYER3_CHALLENGE1);
        assertEq(bitarenaChallenge.getDisputeParticipantsCount(), 1);
        
        //PLAYER1 wants to participate to a dispute as well
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         

        assertEq(bitarenaChallenge.getDisputeParticipants(1), PLAYER1_CHALLENGE1);
        assertEq(bitarenaChallenge.getDisputeParticipantsCount(), 2);

        //PLAYER2 (=team2) wants to participate to a dispute but PLAYER3 from the same team did it
        //So it must revert with error 'TeamOfSignerAlreadyParticipatesInDisputeError'
        vm.expectRevert(TeamOfSignerAlreadyParticipatesInDisputeError.selector);
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         

        //ADMIN of the CHALLENGE wants to refund dispute amount but it fails because there 2 disputers and 
        // the refund is possible if there is only 1 disputer
        vm.expectRevert(RefundImpossibleDueToTooManyDisputeParticipantsError.selector);
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.refundDisputeAmount();
        vm.stopBroadcast();         
    }   

        /** 
     * @dev Test that if there a dispute, a dispute participation is impossible after the delay set by the admin
     */
    function testDispute14() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //There is a dispute so anyone can participate to a dispute
        //PLAYER1 wants to participate to a dispute after a wrong delay : it reverts with TimeElapsedForDisputeParticipationError
        uint256 amountDispute = bitarenaChallenge.getDisputeAmountParticipation();

        vm.warp(block.timestamp + 5 days);
        vm.expectRevert(TimeElapsedForDisputeParticipationError.selector);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         

        assertEq(true, true);
    }   



    /********  TESTS ON CHALLENGE POOL WITHDRAW ***************/
    /**
     * @dev Test that it's impossible for a team to withdraw the pool if no team participate to the dispute
     * 
     */
    function testPoolWithdraw1() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //PLAYER1 participates to the dispute
        vm.expectRevert(NoDisputeParticipantsError.selector);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.withdrawChallengePool();
        vm.stopBroadcast();         
    }

    /**
     * @dev Test that it's impossible for a team to withdraw the pool if a player is not authorized 
     * (i.e. GAMER_ROLE or CHALLENGE_CREATOR_ROLE)
     */
    function testPoolWithdraw2() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 that is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER4 wants to withdraw the pool as he did not participate to the challenge
        vm.expectRevert(WithdrawPoolNotAuthorized.selector);
        vm.startBroadcast(PLAYER4_CHALLENGE1);
        bitarenaChallenge.withdrawChallengePool();
        vm.stopBroadcast();         
    }

    /**
     * @dev Test that it's possible for a signer to withdraw the pool if he's a member of the only one dispute team
     */
    function testPoolWithdraw3() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //PLAYER3 participates to the dispute 1 hour after the "claim victory period"
        vm.warp(bitarenaChallenge.getChallengeStartDate() + bitarenaChallenge.getDelayStartVictoryClaim() + bitarenaChallenge.getDelayEndVictoryClaim() + 1 hours);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        uint256 amountDispute = bitarenaChallenge.getDisputeAmountParticipation();
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         

        assertEq(bitarenaChallenge.getWinnerTeam(), bitarenaChallenge.getTeamOfPlayer(PLAYER3_CHALLENGE1));
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.withdrawChallengePool();
        vm.stopBroadcast();         

    }

    /**
     * @dev Test that it's possible for a signer to withdraw the pool if he's a member of the only one dispute team
     */
    function testPoolWithdraw4() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //PLAYER3 participates to the dispute 1 hour after the "claim victory period"
        vm.warp(bitarenaChallenge.getChallengeStartDate() + bitarenaChallenge.getDelayStartVictoryClaim() + bitarenaChallenge.getDelayEndVictoryClaim() + 1 hours);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        uint256 amountDispute = bitarenaChallenge.getDisputeAmountParticipation();
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         

        //PLAYER2 withdraw the pool and is autorized to do it as he's a member of the winner team like the PLAYER3 
        // So 1 member can sign the tx to participate to a dispute and another member of the same team can withdraw
        assertEq(bitarenaChallenge.getWinnerTeam(), bitarenaChallenge.getTeamOfPlayer(PLAYER3_CHALLENGE1));
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.withdrawChallengePool();
        vm.stopBroadcast();         

        //If the member of the winner team triesto withdraw the pool twice ==> it reverts with error
        vm.expectRevert(ChallengePoolAlreadyWithdrawed.selector);
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.withdrawChallengePool();
        vm.stopBroadcast();         
    }

    /**
     * @dev Test that it's impossible for a signer to withdraw the pool with only 1 disputer if he's a member of a looser team
     */
    function testPoolWithdraw5() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 that is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //PLAYER3 participates to the dispute 1 hour after the "claim victory period" and that's the only disputer of the dispute
        vm.warp(bitarenaChallenge.getChallengeStartDate() + bitarenaChallenge.getDelayStartVictoryClaim() + bitarenaChallenge.getDelayEndVictoryClaim() + 1 hours);
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        uint256 amountDispute = bitarenaChallenge.getDisputeAmountParticipation();
        bitarenaChallenge.participateToDispute{value: amountDispute}();
        vm.stopBroadcast();         

        vm.expectRevert(WithdrawPoolByLooserTeamImpossibleError.selector);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.withdrawChallengePool();
        vm.stopBroadcast();         

    }

    //TODO : TEST reveal winner by admin challenge
    function testRevealWinner1() public {
        BitarenaChallenge bitarenaChallenge = createChallengeWith2TeamsAnd2Players();
        joinTeamWith2PlayersPerTeam(bitarenaChallenge);

        //The admin of the challenge set delay for victory claim
        //With that example, the victory claim is possible between 10 hours after the start date and 20 hours after the start date 
        vm.startBroadcast(ADMIN_CHALLENGE1);
        bitarenaChallenge.setDelayStartForVictoryClaim(10 hours);
        bitarenaChallenge.setDelayEndForVictoryClaim(20 hours);
        vm.stopBroadcast();         

        //As the challenge must start 1 day after its creation, 
        // the PLAYER3 tries to claim the victory for the team1 taht is not his team (=team2)
        uint256 _3DaysInTheFuture = block.timestamp + 2 days;
        vm.warp(_3DaysInTheFuture);

        //PLAYER1 claims victory for his team = team1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         

        //PLAYER3 claims victory for his team = team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.claimVictory(2);
        vm.stopBroadcast();         

        //The challenge DISPUTE ADMIN revealed team 1 as the winner : it reverts because to reveal the winner, the dispute mustcontain at least 2 participants
        // At this stage, we have any dispute participants 
        vm.expectRevert(RevealWinnerImpossibleDueToTooFewDisputersError.selector);
        vm.startBroadcast(ADMIN_DISPUTE_CHALLENGE1);
        bitarenaChallenge.revealWinnerAfterDispute(1);
        vm.stopBroadcast();         

        //PLAYER1 (team1) participates to a dispute
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.claimVictory(1);
        vm.stopBroadcast();         



    }




    //TODO : TEST withdraw pool

    //TODO : Tests balance of challenge smart contract after many joining teams

    
    

    //TODO : Test after revert is done, state variables are rolled back well


}
