// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BitarenaFactory} from "../src/BitarenaFactory.sol";
import {BitarenaToken} from "../src/BitarenaToken.sol";
import {BalanceChallengeCreatorError, ChallengeAdminAddressZeroError, 
    ChallengeCounterError, ChallengeCreatorAddressZeroError, ChallengeLitigationAdminAddressZeroError, ChallengeGameError, 
    ChallengeNameError, ChallengePlatformError, 
    ChallengeStartDateError, NbTeamsError, NbPlayersPerTeamsError, SendMoneyToChallengeError} from '../src/BitarenaFactoryErrors.sol';
import {Challenge} from '../src/ChallengeStruct.sol';
import {BitarenaChallenge} from '../src/BitarenaChallenge.sol';
import {ChallengeCancelAfterStartDateError, NbTeamsLimitReachedError, NbPlayersPerTeamsLimitReachedError} from "../src/BitarenaChallengeErrors.sol";


contract BitarenaTest is Test {
    BitarenaFactory public bitarenaFactory;
    address ADMIN_FACTORY = makeAddr("adminFactory");
    address ADMIN_CHALLENGE1 = makeAddr("adminChallenge1");
    address ADMIN_CHALLENGE2 = makeAddr("adminChallenge2");
    address ADMIN_LITIGATION_CHALLENGE1 = makeAddr("adminLitigationChallenge1");
    address ADMIN_LITIGATION_CHALLENGE2 = makeAddr("adminLitigationChallenge2");
    address CREATOR_CHALLENGE1 = makeAddr("creatorChallenge1");
    address CREATOR_CHALLENGE2 = makeAddr("creatorChallenge2");
    address PLAYER1_CHALLENGE1 = makeAddr("player1Challenge1");
    address PLAYER2_CHALLENGE1 = makeAddr("player2Challenge1");
    address PLAYER3_CHALLENGE1 = makeAddr("player3Challenge1");

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


    uint256 private constant STARTING_BALANCE_ETH = 10 ether; 

    function setUp() public {
        //BitarenaToken bitarenaToken = new BitarenaToken();

        vm.deal(CREATOR_CHALLENGE1, STARTING_BALANCE_ETH);
        vm.deal(CREATOR_CHALLENGE2, STARTING_BALANCE_ETH);
        vm.deal(PLAYER1_CHALLENGE1, STARTING_BALANCE_ETH);
        vm.deal(PLAYER2_CHALLENGE1, STARTING_BALANCE_ETH);
        vm.deal(PLAYER3_CHALLENGE1, STARTING_BALANCE_ETH);
    }

    function deployFactory() public {
        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory = new BitarenaFactory();
        vm.stopBroadcast();
        vm.deal(address(bitarenaFactory), STARTING_BALANCE_ETH);
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
        assertEq(bitarenaFactory.getChallengeCounter(), 1);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation1() public {
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

        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 

        vm.stopBroadcast();
        assertEq(challengeStructCreated.challengeName, CHALLENGE1);
    }
    /**
     * @dev Test value of state var "s_challengesName" after intent challenge creation 
     */
    function testStateVariableAfterChallengeDeployment1() public {
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

        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getName(), CHALLENGE1);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation2() public {
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

        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 

        vm.stopBroadcast();
        assertEq(challengeStructCreated.game, GAME1);
    }

    /**
     * @dev Test value of state var "s_game" after challenge creation/deployment
     */
    function testStateVariableAfterChallengeDeployment2() public {
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

        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getGame(), GAME1);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation3() public {
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

        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 

        vm.stopBroadcast();
        assertEq(challengeStructCreated.platform, PLATFORM1);
    }

    /**
     * @dev Test value of mapping state var "s_platform" after challenge creation/deployment 
     */
    function testStateVariableAfterChallengeDeployment3() public {
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

        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getPlatform(), PLATFORM1);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation4() public {
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

        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 

        vm.stopBroadcast();
        assertEq(challengeStructCreated.nbTeams, TWO_TEAMS);
    }

    /**
     * @dev Test value of state var "s_nbTeams" after challenge creation/deployment 
     */
    function testStateVariableAfterChallengeDeployment4() public {
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

        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 
        vm.stopBroadcast();

        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getNbTeams(), TWO_TEAMS);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation5() public {
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

        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 

        vm.stopBroadcast();
        assertEq(challengeStructCreated.nbTeamPlayers, ONE_PLAYER);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation6() public {
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

        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 

        vm.stopBroadcast();
        assertEq(challengeStructCreated.amountPerPlayer, AMOUNT_PER_PLAYER);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation7() public {
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

        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 

        vm.stopBroadcast();
        assertEq(challengeStructCreated.startAt, block.timestamp + 1 days);
    }

    /**
     * @dev Test value of mapping "s_challengesMap" after intent challenge creation 
     */
    function testStateVariableAfterIntentChallengeCreation8() public {
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

        Challenge memory challengeStructCreated = bitarenaFactory.getChallengeByIndex(1); 

        vm.stopBroadcast();
        assertEq(challengeStructCreated.isPrivate, false);
    }

    /**
     * @dev Test balance of Factory smart contract after intent challenge creation 
     */
    function testBalanceFactoryAfterIntentChallengeCreation8() public {
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
        assertEq(address(bitarenaFactory).balance, AMOUNT_PER_PLAYER+STARTING_BALANCE_ETH);
    }

    /**
     * @dev Test balance of challenge creator after intent challenge creation 
     */
    function testBalanceCreatorAfterIntentChallengeCreation8() public {
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
        assertEq(address(CREATOR_CHALLENGE1).balance, STARTING_BALANCE_ETH - AMOUNT_PER_PLAYER);
    }

    /**
     * @dev Test challenge creation fails if a bad index is provided (= not exists )
     */
    function testChallengeCreationRevertIfBAdCounterIsProvided() public {
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

        vm.expectRevert(ChallengeCounterError.selector);
        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 2);
        vm.stopBroadcast();       
    }

    /**
     * @dev Test balance factory before deploying a challenge
     * The factory owns 'STARTING_BALANCE_ETH' before the challenge intent creation
     * After the Challenge intent creation it must own 'STARTING_BALANCE_ETH' + AMOUNT_PER_PLAYER
     */
    function testBalanceFactoryBeforeDeployingChallenge() public {
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

        vm.startBroadcast(ADMIN_FACTORY);
        // BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
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

        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(address(bitarenaFactory).balance, STARTING_BALANCE_ETH);
    }

    /**
     * @dev Test that the property 'challengeAddress' is correctly hydrated after Challenge Deployment
     * 
     */
    function testChallengeAddressInStateVariableStructAfterDeploying() public {
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

        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaFactory.isChallengeDeployed(1), true);
    }

    /**
     * @dev Test that the property 'challengeAddress' is equal to address(0) before Challenge deployment
     * 
     */
    function testChallengeAddressInStateVariableStructBeforeDeploying() public {
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

        assertEq(bitarenaFactory.isChallengeDeployed(1), false);
    }

    /**
     * @dev Test that the first team is created after Challenge deployment
     * 
     */
    function testFirstTeamCreatedAfterChallengeDeployment() public {
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

        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        assertEq(bitarenaChallenge.getTeamCounter(), 1);
    }

    /**
     * @dev Test that the only player in the first team after Challenge deployment is the challenge creator
     * 
     */
    function testFirstTeamCreatedAfterChallengeDeploymentContainsOnlyCreator() public {
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

        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       
        
        assertEq(bitarenaChallenge.getPlayersByTeamIndex(1)[0], bitarenaChallenge.getCreator());
    }

    /**
     * @dev Test that if the Challenge is set with only 1 player per team, anyone can join the team created by the creator 
     * as it's the unique player in his team
     * 
     */
    function testPlayerCanNotJoinTeamIfCreatorCreateChallengeWithOnlyOnePlayerPerTeam() public {
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

        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        vm.expectRevert(NbPlayersPerTeamsLimitReachedError.selector);
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.joinOrCreateTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               
    }

    /**
     * @dev Test that a player can create a team if nb teams limit is OK
     * as it's the unique player in his team
     * Case of challenge that is set with 2 teams and only 1 player per team
     */
    function testPlayerCanCreateTeamIfNbTeamsLimitIsOk() public {
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

        vm.startBroadcast(ADMIN_FACTORY);
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.joinOrCreateTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               

        //Test that data are OK : 
        //teamCounter = 2
        //creator is the only player in the team 1
        //PLAYER1_CHALLENGE1 is the only player in the team 2
        assertEq(bitarenaChallenge.getTeamCounter(), 2);
        assertEq(bitarenaChallenge.getPlayersByTeamIndex(1)[0], bitarenaChallenge.getCreator());
        assertEq(bitarenaChallenge.getPlayersByTeamIndex(2)[0], PLAYER1_CHALLENGE1);
        assertEq(bitarenaChallenge.getPlayersByTeamIndex(1).length, 1);
        assertEq(bitarenaChallenge.getPlayersByTeamIndex(2).length, 1);
    }

    /**
     * @dev Test that some players can join teams if limits are ok
     * Case of challenge that is set with 2 teams and 2 players per team
     */
    function testPlayersCanJoinExistingTeamsIfLimitIsOk() public {
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
        BitarenaChallenge bitarenaChallenge = bitarenaFactory.createChallenge(ADMIN_CHALLENGE1, ADMIN_LITIGATION_CHALLENGE1, 1);
        vm.stopBroadcast();       

        //send players some native tokens to enable them to jointeams
        //A second player joins the team 1
        vm.startBroadcast(PLAYER1_CHALLENGE1);
        bitarenaChallenge.joinOrCreateTeam{value: AMOUNT_PER_PLAYER}(1);
        vm.stopBroadcast();               


        //The PLAYER2 creates a new team : team with index 2 is created
        vm.startBroadcast(PLAYER2_CHALLENGE1);
        bitarenaChallenge.joinOrCreateTeam{value: AMOUNT_PER_PLAYER}(0);
        vm.stopBroadcast();               

        //The PLAYER3 joins the team2
        vm.startBroadcast(PLAYER3_CHALLENGE1);
        bitarenaChallenge.joinOrCreateTeam{value: AMOUNT_PER_PLAYER}(2);
        vm.stopBroadcast();               

        //Test that data are OK : 
        //teamCounter = 2
        //creator and PLAYER1 are players of team 1
        //PLAYER2 and PLAYER3 are players of team 2
        assertEq(bitarenaChallenge.getTeamCounter(), 2);
        assertEq(bitarenaChallenge.getPlayersByTeamIndex(1)[0], bitarenaChallenge.getCreator());
        assertEq(bitarenaChallenge.getPlayersByTeamIndex(1)[1], PLAYER1_CHALLENGE1);
        assertEq(bitarenaChallenge.getPlayersByTeamIndex(2)[0], PLAYER2_CHALLENGE1);
        assertEq(bitarenaChallenge.getPlayersByTeamIndex(2)[1], PLAYER3_CHALLENGE1);
    }

}
