// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { BitarenaChallenge } from './BitarenaChallenge.sol';
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {BalanceChallengeCreatorError, ChallengeAdminAddressZeroError, 
    ChallengeCounterError, ChallengeCreatorAddressZeroError, ChallengeLitigationAdminAddressZeroError, ChallengeGameError, 
    ChallengeNameError, ChallengePlatformError, 
    ChallengeStartDateError, NbTeamsError, NbPlayersPerTeamsError, SendMoneyToChallengeError} from './BitarenaFactoryErrors.sol';
import {IntentChallengeCreation, ChallengeDeployed} from './BitarenaFactoryEvents.sol';

contract BitarenaFactory is Context, Ownable, AccessControl {

    uint private s_challengeCounter;

    struct Challenge {
        address challengeCreator;
        address challengeAddress;
		string challengeName;
        string game;
        string platform;
        uint16 nbTeams;
        uint16 nbTeamPlayers;
        uint amountPerPlayer;
        uint startAt;
        bool isPrivate;
	}   

    mapping(uint indexChallenge => Challenge) s_challengesMap;
    Challenge[] s_challengesArray;

    bytes32 public constant BITARENA_FACTORY_ADMIN = keccak256("BITARENA_FACTORY_ADMIN");

    Challenge[] private s_challenges;

	constructor () Ownable(msg.sender) {
        s_challengeCounter = 0;
		_grantRole(BITARENA_FACTORY_ADMIN, msg.sender);
	}

    function intentChallengeCreation(
        string memory _challengeName,
        string memory _game,
        string memory _platform,
        uint16 _nbTeams,
        uint16 _nbTeamPlayers,
        uint _amountPerPlayer,
        uint _startAt,
        bool _isPrivate
    ) public payable {
        if (bytes(_challengeName).length == 0) revert ChallengeNameError();
        if (bytes(_game).length == 0) revert ChallengeGameError();
        if (bytes(_platform).length == 0) revert ChallengePlatformError();
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
        newChallenge.challengeName = _challengeName;
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
        address _challengeLitigationAdmin,
        uint _challengeCounter
    ) public onlyRole(BITARENA_FACTORY_ADMIN){
        if (_challengeCounter > s_challengeCounter) revert ChallengeCounterError();

        Challenge memory challenge = s_challengesMap[_challengeCounter];

        if(challenge.challengeCreator == address(0)) revert ChallengeCreatorAddressZeroError();
        if(_challengeAdmin == address(0)) revert ChallengeAdminAddressZeroError();
        if(_challengeLitigationAdmin == address(0)) revert ChallengeLitigationAdminAddressZeroError();
        

        BitarenaChallenge bitarenaChallenge = new BitarenaChallenge(
            _challengeAdmin, 
            _challengeLitigationAdmin, 
            challenge.challengeCreator, 
            challenge.challengeName, 
            challenge.game, 
            challenge.platform, 
            challenge.nbTeams, 
            challenge.nbTeamPlayers, 
            challenge.amountPerPlayer, 
            challenge.startAt, 
            challenge.isPrivate
        );

        //Hydrate challenges array
        challenge.challengeAddress = address(bitarenaChallenge);
        s_challenges.push(challenge);

        //Send amountPerPlayer from creator to challenge smart contract
        (bool sent, ) = address(bitarenaChallenge).call{value: challenge.amountPerPlayer}("");
        if (!sent) revert SendMoneyToChallengeError();

        emit ChallengeDeployed(_challengeCounter, address(bitarenaChallenge));
    }
}
