// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { BitarenaChallenge } from './BitarenaChallenge.sol';
import { ChallengeCreated } from './BitarenaFactoryEvents.sol';
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ChallengeCreatorAddressZeroError} from './BitarenaFactoryErrors.sol';
import {ChallengeAdminAddressZeroError} from './BitarenaFactoryErrors.sol';
import {ChallengeLitigationAdminAddressZeroError} from './BitarenaFactoryErrors.sol';
import {NbTeamsError} from './BitarenaFactoryErrors.sol';
import {NbPlayersPerTeamsError} from './BitarenaFactoryErrors.sol';
import {ChallengeCreated} from './BitarenaFactoryEvents.sol';

contract BitarenaFactory is Ownable, AccessControl {

    struct Challenge {
		BitarenaChallenge challenge;
		string name;
	}    

    bytes32 public constant BITARENA_FACTORY_ADMIN = keccak256("BITARENA_FACTORY_ADMIN");

	constructor () Ownable(msg.sender) {
		_grantRole(BITARENA_FACTORY_ADMIN, msg.sender);
	}

    function createChallenge(
        address _challengeAdmin,
        address _challengeLitigationAdmin,
        address _challengeCreator,
        string memory _challengeName,
        string memory _game,
        string memory _platform,
        uint16 _nbTeams,
        uint16 _nbTeamPlayers,
        uint _startAt,
        bool _isPrivate
    ) onlyRole(BITARENA_FACTORY_ADMIN) public {
        if(_challengeCreator == address(0)) revert ChallengeCreatorAddressZeroError();
        if(_challengeAdmin == address(0)) revert ChallengeAdminAddressZeroError();
        if(_challengeLitigationAdmin == address(0)) revert ChallengeLitigationAdminAddressZeroError();
        if(_nbTeams < 2) revert NbTeamsError();
        if(_nbTeamPlayers < 1) revert NbPlayersPerTeamsError();

        BitarenaChallenge bitarenaChallenge = new BitarenaChallenge(_challengeAdmin, _challengeLitigationAdmin,  _challengeCreator, _challengeName, _game, _platform, _nbTeams, _nbTeamPlayers, _startAt, _isPrivate);

        emit ChallengeCreated(_challengeName, address(bitarenaChallenge));
    }
}
