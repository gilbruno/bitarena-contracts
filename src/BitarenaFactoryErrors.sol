// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

/**
 * @dev 
 */
error AddressZeroError();

/**
 * @dev 
 */
error BalanceChallengeCreatorError();


/**
 * @dev an unexpected zero address was transmitted. (eg. `address(0)`)
 */
error ChallengeCreatorAddressZeroError();

/**
 * @dev 
 */
error ChallengeCounterError();

/**
 * @dev 
 */
error ChallengeDeployedError();

/**
 * @dev an unexpected zero address was transmitted for the Challenge Admin. (eg. `address(0)`)
 */
error ChallengeAdminAddressZeroError();

/**
 * @dev an unexpected zero address was transmitted for the Challenge Dispute Admin. (eg. `address(0)`)
 */
error ChallengeDisputeAdminAddressZeroError();

/**
 * @dev 
 */
error ChallengeGameError();

/**
 * @dev 
 */
error ChallengePlatformError();

/**
 * @dev 
 */
error ChallengeStartDateError();

/**
 * @dev an incorrect value for game
 */
error GameDoesNotExistError();


/**
 * @dev an incorrect value for nbTeams
 */
error NbTeamsError();

/**
 * @dev an incorrect value for nbPlayersPerTeam
 */
error NbPlayersPerTeamsError();

/**
 * @dev an incorrect value for platform
 */
error PlatformDoesNotExistError();

/**
 * @dev 
 */
error SendMoneyToChallengeError();

