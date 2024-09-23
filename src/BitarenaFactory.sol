// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { BitarenaChallenge } from './BitarenaChallenge.sol';
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {BalanceChallengeCreatorError, ChallengeAdminAddressZeroError, 
    ChallengeCounterError, ChallengeDeployedError, ChallengeCreatorAddressZeroError, ChallengeDisputeAdminAddressZeroError, ChallengeGameError, 
    ChallengePlatformError, ChallengeStartDateError, NbTeamsError, NbPlayersPerTeamsError, SendMoneyToChallengeError} from './BitarenaFactoryErrors.sol';
import {IntentChallengeCreation, ChallengeDeployed} from './BitarenaFactoryEvents.sol';
import {Challenge} from './ChallengeStruct.sol';
import {ChallengeParams} from './ChallengeParams.sol';

contract BitarenaFactory is Context, Ownable, AccessControl {

    uint256 private s_challengeCounter;


    mapping(uint256 indexChallenge => Challenge) private s_challengesMap;
    
    Challenge[] private s_challenges;
    
    bytes32 public constant BITARENA_FACTORY_ADMIN = keccak256("BITARENA_FACTORY_ADMIN");

	constructor () Ownable(msg.sender) {
        s_challengeCounter = 0;
		_grantRole(BITARENA_FACTORY_ADMIN, msg.sender);
	}

    function intentChallengeCreation(
        bytes32 _game,
        bytes32 _platform,
        uint16 _nbTeams,
        uint16 _nbTeamPlayers,
        uint256 _amountPerPlayer,
        uint256 _startAt,
        bool _isPrivate
    ) public payable {
        if (_game == 0) revert ChallengeGameError();
        if (_platform == 0) revert ChallengePlatformError();
        if(_nbTeams < 2) revert NbTeamsError();
        if(_nbTeamPlayers < 1) revert NbPlayersPerTeamsError();
        if (_startAt <= block.timestamp) revert ChallengeStartDateError();
        if (msg.value < _amountPerPlayer) revert BalanceChallengeCreatorError();

        //Increment counter of challenges
        s_challengeCounter++;
        //Create challenge struct
        Challenge memory newChallenge;
        newChallenge.challengeCreator = _msgSender();
        newChallenge.challengeAddress = address(0);
        newChallenge.game = _game;
        newChallenge.platform = _platform;
        newChallenge.nbTeams = _nbTeams;
        newChallenge.nbTeamPlayers = _nbTeamPlayers;
        newChallenge.amountPerPlayer = _amountPerPlayer;
        newChallenge.startAt = _startAt;
        newChallenge.isPrivate = _isPrivate;
        //Hydrate the challenges mapping
        s_challengesMap[s_challengeCounter] = newChallenge;

        emit IntentChallengeCreation(s_challengeCounter);
    }


    function createChallenge(
        address _challengeAdmin,
        address _challengeDisputeAdmin,
        uint256 _challengeCounter
    ) public onlyRole(BITARENA_FACTORY_ADMIN) returns (BitarenaChallenge){
        if (_challengeCounter > s_challengeCounter) revert ChallengeCounterError();
        if (isChallengeDeployed(_challengeCounter)) revert ChallengeDeployedError();

        Challenge memory challenge = s_challengesMap[_challengeCounter];

        if(challenge.challengeCreator == address(0)) revert ChallengeCreatorAddressZeroError();
        if(_challengeAdmin == address(0)) revert ChallengeAdminAddressZeroError();
        if(_challengeDisputeAdmin == address(0)) revert ChallengeDisputeAdminAddressZeroError();
        

        ChallengeParams memory challengeParams = ChallengeParams({
            factory: address(this),
            challengeAdmin: _challengeAdmin,
            challengeDisputeAdmin: _challengeDisputeAdmin,
            challengeCreator: challenge.challengeCreator,
            game: challenge.game,
            platform: challenge.platform,
            nbTeams: challenge.nbTeams,
            nbTeamPlayers: challenge.nbTeamPlayers,
            amountPerPlayer: challenge.amountPerPlayer,
            startAt: challenge.startAt,
            isPrivate: challenge.isPrivate
        });

        BitarenaChallenge bitarenaChallenge = new BitarenaChallenge(challengeParams);

        //Hydrate challenges array
        s_challengesMap[_challengeCounter].challengeAddress = address(bitarenaChallenge);
        s_challenges.push(challenge);

        //Create the firstTeam and add the creator of the challenge in this first team
        bitarenaChallenge.createOrJoinTeam(0);

        //Send amountPerPlayer from creator to challenge smart contract
        (bool sent, ) = address(bitarenaChallenge).call{value: challenge.amountPerPlayer}("");
        if (!sent) revert SendMoneyToChallengeError();

        emit ChallengeDeployed(_challengeCounter, address(bitarenaChallenge), address(this));

        return bitarenaChallenge;
    }

    function deployAndCreateChallenge() public {
        
    }

    /**
     * @dev Getter for 's_challengeCounter'
     */
    function getChallengeCounter() public view returns (uint256) {
        return s_challengeCounter;
    }

    /**
     * @dev Getter for the 's_challengesMap' by index
     * @param index : index of the mapping
     */
    function getChallengeByIndex(uint256 index) public view returns(Challenge memory) {
        return s_challengesMap[index];
    }

    /**
     * @dev Getter for s_challenges
     */
    function getChallengesArray() public view returns (Challenge[] memory) {
        return s_challenges;
    }

    function isChallengeDeployed(uint256 index) public view returns(bool) {
        Challenge memory challengeCreated = getChallengeByIndex(index);
        return (challengeCreated.challengeAddress != address(0));
    }
}
