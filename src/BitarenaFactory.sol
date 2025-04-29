// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { BitarenaChallenge } from './BitarenaChallenge.sol';
/*
Replace with these imports to test in Remix
import {Ownable} from "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/access/Ownable.sol";
import {AccessControl} from "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/access/AccessControl.sol";
import {Context} from "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/utils/Context.sol";
*/
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {Challenge} from "./struct/ChallengeStruct.sol";
import {ChallengeParams} from "./struct/ChallengeParams.sol";
import {IBitarenaGames} from "./interfaces/IBitarenaGames.sol";
import {IBitarenaChallengesData} from "./interfaces/IBitarenaChallengesData.sol";
import {BitarenaChallengesData} from "./BitarenaChallengesData.sol";
import {IBitarenaFactory} from "./interfaces/IBitarenaFactory.sol";

contract BitarenaFactory is Context, Ownable, AccessControl, IBitarenaFactory {

    uint256 private s_challengeCounter;

    IBitarenaGames private s_bitarenaGames;

    IBitarenaChallengesData private s_challengesData;

    mapping(uint256 indexChallenge => Challenge) private s_challengesMap;
    
    Challenge[] private s_challenges;
    
    bytes32 public constant BITARENA_FACTORY_ADMIN = keccak256("BITARENA_FACTORY_ADMIN");

    address private immutable s_challengeAdmin;
    address private immutable s_challengeDisputeAdmin;
    address private immutable s_challengeEmergencyAdmin;
	constructor (address _bitarenaGames, address _challengeAdmin, address _challengeDisputeAdmin, address _challengeEmergencyAdmin, address _challengeData) Ownable(msg.sender) {
        if(_bitarenaGames == address(0)) revert BitarenaGamesAddressZeroError();
        if(_challengeAdmin == address(0)) revert ChallengeAdminAddressZeroError();
        if(_challengeDisputeAdmin == address(0)) revert ChallengeDisputeAdminAddressZeroError();
        if(_challengeEmergencyAdmin == address(0)) revert ChallengeEmergencyAdminAddressZeroError();
        if(_challengeData == address(0)) revert ChallengesDataAddressZeroError();
        s_challengeCounter = 0;
        s_bitarenaGames = IBitarenaGames(_bitarenaGames);
        s_challengeAdmin = _challengeAdmin;
        s_challengeDisputeAdmin = _challengeDisputeAdmin;
        s_challengeEmergencyAdmin = _challengeEmergencyAdmin;
        s_challengesData = IBitarenaChallengesData(_challengeData); 
		bool success = _grantRole(BITARENA_FACTORY_ADMIN, msg.sender);
		if (!success) revert RoleGrantFailed();
	}

    modifier checkIntentCreation(string calldata _game,
        string calldata _platform,
        uint16 _nbTeams,
        uint16 _nbTeamPlayers,
        uint256 _amountPerPlayer,
        uint256 _startAt,
        bool _isPrivate) {
            if (keccak256(abi.encodePacked(_game)) == keccak256(abi.encodePacked(""))) revert ChallengeGameError();
            if (keccak256(abi.encodePacked(_platform)) == keccak256(abi.encodePacked(""))) revert ChallengePlatformError();
            if(_nbTeams < 2) revert NbTeamsError();
            if(_nbTeamPlayers < 1) revert NbPlayersPerTeamsError();
            if (_startAt <= block.timestamp) revert ChallengeStartDateError();
            if (msg.value < _amountPerPlayer) revert BalanceChallengeCreatorError();
            if (!gameExists(_game)) revert GameDoesNotExistError();
            if (!platformExists(_platform)) revert PlatformDoesNotExistError();
            _;
    }

    /**
     * @dev Returns true if a game exists in the state var array of games of BitarenaGames smart contract
     * False otherwise
     */
    // aderyn-ignore-next-line(internal-function-used-once)
    function gameExists(string memory _game) internal view returns(bool) {
        string[] memory games = s_bitarenaGames.getGames();
        bool _gameExists = false;
        for (uint256 i = 0; i < games.length; i++) {
            if (keccak256(abi.encodePacked(games[i])) == keccak256(abi.encodePacked(_game))) {
                _gameExists = true;
                break;
            }
        }
        return _gameExists;
    }
    /**
     * @dev Returns true if a platform exists in the state var array of platforms of BitarenaGames smart contract.
     * False otherwise
     */
    // aderyn-ignore-next-line(internal-function-used-once)
    function platformExists(string memory _platform) internal view returns(bool) {
        string[] memory platforms = s_bitarenaGames.getPlatforms();
        bool _platformExists = false;
        for (uint256 i = 0; i < platforms.length; i++) {
            if (keccak256(abi.encodePacked(platforms[i])) == keccak256(abi.encodePacked(_platform))) {
                _platformExists = true;
                break;
            }
        }
        return _platformExists;

    }
    /**
     * Intent challenge creation. This function must be used in case the process is divided in 2 steps :
     * Step 1 : A gamer wants to create a challeneg and sign a tx to intent a challenge Creation
     * Step 1 : The Bitarena protocol is in charge to deploy the SC og the challenge
     */
    function intentChallengeCreation(
        string calldata _game,
        string calldata _platform,
        uint16 _nbTeams,
        uint16 _nbTeamPlayers,
        uint256 _amountPerPlayer,
        uint256 _startAt,
        bool _isPrivate
    ) external payable checkIntentCreation(_game, _platform, _nbTeams, _nbTeamPlayers, _amountPerPlayer, _startAt, _isPrivate) {
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

    /**
     * Intent challenge creation + deployment version 2. This function must be used in case the process is  :
     * A gamer wants to create a challeneg and sign a tx to intent a challenge Creation and deploy a SC of challenge so he's in charge of deploying SC of challenge
     * In that case we call the function 'createChallenge_byCreator' inside
     */
    function intentChallengeDeployment(
        string calldata _game,
        string calldata _platform,
        uint16 _nbTeams,
        uint16 _nbTeamPlayers,
        uint256 _amountPerPlayer,
        uint256 _startAt,
        bool _isPrivate
    ) external payable checkIntentCreation(_game, _platform, _nbTeams, _nbTeamPlayers, _amountPerPlayer, _startAt, _isPrivate) returns (BitarenaChallenge) {
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

        BitarenaChallenge bitarenaChallenge = createChallenge_byCreator(s_challengeCounter);
        return bitarenaChallenge;
    }

    /**
     * @dev Get the bytecode of BitarenaChallenge SC with ChallengeParams
     */
    function getChallengeBytecode(ChallengeParams memory _params) public pure returns (bytes memory) {
        bytes memory bytecode = type(BitarenaChallenge).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_params));
    }

    function deployChallenge(uint256 _salt, ChallengeParams memory _params) internal returns (address payable) {
        address payable addr;
        
        // Get bytecode with the struct ChallengeParams as constructor argument
        bytes memory bytecode = getChallengeBytecode(_params);

        assembly {
            // Deploy the contract using CREATE2
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    /**
     * @dev Deploy new Challenge.
     * This function must be used in the case of Bitarena is in charge to deploy new challenge smart contract
     */
    // aderyn-ignore-next-line(internal-function-used-once)
    function createChallenge_byCreator(uint256 _challengeCounter) internal returns (BitarenaChallenge) {
        if (_challengeCounter == 0 || _challengeCounter > s_challengeCounter) revert ChallengeCounterError();
        if (isChallengeDeployed(_challengeCounter)) revert ChallengeDeployedError();

        Challenge memory challenge = s_challengesMap[_challengeCounter];

        if(challenge.challengeCreator == address(0)) revert ChallengeCreatorAddressZeroError();
        
        //Generate salt based on deterministic output 
        uint256 salt = uint256(keccak256(abi.encodePacked(string(abi.encodePacked("bitarena", _challengeCounter)))));

        address deployedChallengeAddress = deployChallenge(salt, ChallengeParams({
            factory: address(this),
            challengesData: address(s_challengesData),
            challengeAdmin: s_challengeAdmin,
            challengeDisputeAdmin: s_challengeDisputeAdmin,
            challengeEmergencyAdmin: s_challengeEmergencyAdmin,
            challengeCreator: challenge.challengeCreator,
            game: challenge.game,
            platform: challenge.platform,
            nbTeams: challenge.nbTeams,
            nbTeamPlayers: challenge.nbTeamPlayers,
            amountPerPlayer: challenge.amountPerPlayer,
            startAt: challenge.startAt,
            isPrivate: challenge.isPrivate
            }));

        BitarenaChallenge bitarenaChallenge = BitarenaChallenge(payable(deployedChallengeAddress));

        //Hydrate challenges array
        s_challengesMap[_challengeCounter].challengeAddress = deployedChallengeAddress;
        challenge.challengeAddress = deployedChallengeAddress;
        s_challenges.push(challenge);

        //Send amountPerPlayer from creator to challenge smart contract first
        (bool sent, ) = address(bitarenaChallenge).call{value: challenge.amountPerPlayer}("");
        if (!sent) revert SendMoneyToChallengeError();

        // Enregistrement du challenge dans BitarenaChallengesData avant de créer la première équipe
        s_challengesData.registerChallengeContract(address(deployedChallengeAddress));

        //Create the firstTeam and add the creator of the challenge in this first team after funds are sent
        bitarenaChallenge.createOrJoinTeam(0);

        emit ChallengeDeployed(_challengeCounter, address(bitarenaChallenge), address(this));

        return bitarenaChallenge;
    }

    /**
     * @dev Deploy new Challenge.
     * This function must be used in the case of Bitarena is in charge to deploy new challenge smart contract
     */
    function createChallenge(
        address _challengeAdmin,
        address _challengeDisputeAdmin,
        uint256 _challengeCounter
    ) external onlyRole(BITARENA_FACTORY_ADMIN) returns (BitarenaChallenge){
        if (_challengeCounter == 0 || _challengeCounter > s_challengeCounter) revert ChallengeCounterError();
        if (isChallengeDeployed(_challengeCounter)) revert ChallengeDeployedError();

        Challenge memory challenge = s_challengesMap[_challengeCounter];

        if(challenge.challengeCreator == address(0)) revert ChallengeCreatorAddressZeroError();
        if(_challengeAdmin == address(0)) revert ChallengeAdminAddressZeroError();
        if(_challengeDisputeAdmin == address(0)) revert ChallengeDisputeAdminAddressZeroError();
        
        //Generate salt based on deterministic output 
        uint256 salt = uint256(keccak256(abi.encodePacked(string(abi.encodePacked("bitarena", _challengeCounter)))));

        address deployedChallengeAddress = deployChallenge(salt, ChallengeParams({
            factory: address(this),
            challengesData: address(s_challengesData),
            challengeAdmin: _challengeAdmin,
            challengeDisputeAdmin: _challengeDisputeAdmin,
            challengeEmergencyAdmin: s_challengeEmergencyAdmin,
            challengeCreator: challenge.challengeCreator,
            game: challenge.game,
            platform: challenge.platform,
            nbTeams: challenge.nbTeams,
            nbTeamPlayers: challenge.nbTeamPlayers,
            amountPerPlayer: challenge.amountPerPlayer,
            startAt: challenge.startAt,
            isPrivate: challenge.isPrivate
            }));

        BitarenaChallenge bitarenaChallenge = BitarenaChallenge(payable(deployedChallengeAddress));

        //Hydrate challenges array
        s_challengesMap[_challengeCounter].challengeAddress = deployedChallengeAddress;
        challenge.challengeAddress = deployedChallengeAddress;
        s_challenges.push(challenge);

        //Send amountPerPlayer from creator to challenge smart contract first
        (bool sent, ) = address(bitarenaChallenge).call{value: challenge.amountPerPlayer}("");
        if (!sent) revert SendMoneyToChallengeError();

        // Enregistrement du challenge dans BitarenaChallengesData avant de créer la première équipe
        s_challengesData.registerChallengeContract(address(deployedChallengeAddress));

        //Create the firstTeam and add the creator of the challenge in this first team after funds are sent
        bitarenaChallenge.createOrJoinTeam(0);

        emit ChallengeDeployed(_challengeCounter, address(bitarenaChallenge), address(this));

        return bitarenaChallenge;
    }

    /**
     * @dev Getter for 's_challengeCounter'
     */
    function getChallengeCounter() external view returns (uint256) {
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
    function getChallengesArray() external view returns (Challenge[] memory) {
        return s_challenges;
    }

    function isChallengeDeployed(uint256 index) public view returns(bool) {
        Challenge memory challengeCreated = getChallengeByIndex(index);
        return (challengeCreated.challengeAddress != address(0));
    }
}
