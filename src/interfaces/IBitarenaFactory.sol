// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {BitarenaChallenge} from '../BitarenaChallenge.sol';
import {Challenge} from '../ChallengeStruct.sol';
import {ChallengeParams} from '../struct/ChallengeParams.sol';
interface IBitarenaFactory {
    // Errors
    error AddressZeroError();
    error BalanceChallengeCreatorError();
    error ChallengeCreatorAddressZeroError();
    error ChallengeCounterError();
    error ChallengeDeployedError();
    error ChallengeAdminAddressZeroError();
    error ChallengeDisputeAdminAddressZeroError();
    error ChallengeEmergencyAdminAddressZeroError();
    error ChallengesDataAddressZeroError();
    error ChallengeGameError();
    error ChallengePlatformError();
    error ChallengeStartDateError();
    error GameDoesNotExistError();
    error NbTeamsError();
    error NbPlayersPerTeamsError();
    error PlatformDoesNotExistError();
    error SendMoneyToChallengeError();

    // Events
    event ChallengeDeployed(uint indexed challengeCounter, address indexed challengeAddress, address indexed challengeFactoryAddress);
    event IntentChallengeCreation(uint indexed challengeCounter);

    // Functions
    function intentChallengeCreation(
        string calldata _game,
        string calldata _platform,
        uint16 _nbTeams,
        uint16 _nbTeamPlayers,
        uint256 _amountPerPlayer,
        uint256 _startAt,
        bool _isPrivate
    ) external payable;

    function intentChallengeDeployment(
        string calldata _game,
        string calldata _platform,
        uint16 _nbTeams,
        uint16 _nbTeamPlayers,
        uint256 _amountPerPlayer,
        uint256 _startAt,
        bool _isPrivate
    ) external payable returns (BitarenaChallenge);

    function getChallengeBytecode(ChallengeParams memory _params) external pure returns (bytes memory);

    function createChallenge(
        address _challengeAdmin,
        address _challengeDisputeAdmin,
        uint256 _challengeCounter
    ) external returns (BitarenaChallenge);

    function getChallengeCounter() external view returns (uint256);
    
    function getChallengeByIndex(uint256 index) external view returns (Challenge memory);
    
    function getChallengesArray() external view returns (Challenge[] memory);
    
    function isChallengeDeployed(uint256 index) external view returns (bool);
}