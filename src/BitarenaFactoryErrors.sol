// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

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
 * @dev an unexpected zero address was transmitted for the Challenge Admin. (eg. `address(0)`)
 */
error ChallengeAdminAddressZeroError();

/**
 * @dev an unexpected zero address was transmitted for the Challenge Litigation Admin. (eg. `address(0)`)
 */
error ChallengeLitigationAdminAddressZeroError();

/**
 * @dev 
 */
error ChallengeNameError();

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
 * @dev an incorrect value for nbTeams
 */
error NbTeamsError();

/**
 * @dev an incorrect value for nbPlayersPerTeam
 */
error NbPlayersPerTeamsError();

/**
 * @dev 
 */
error SendMoneyToChallengeError();

