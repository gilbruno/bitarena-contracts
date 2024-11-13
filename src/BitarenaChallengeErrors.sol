// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

/**
 * @dev 
 */
error BalanceChallengePlayerError();

/**
 * @dev 
 */
error ChallengeCanceledError();

/**
 * @dev 
 */
error ChallengeCancelAfterStartDateError();

/**
 * @dev 
 */
error ChallengePoolAlreadyWithdrawed();

/**
 * @dev 
 */
error ClaimVictoryNotAuthorized();

/**
 * @dev 
 */
error DelayClaimVictoryNotSet();

/**
 * @dev 
 */
error DelayUnclaimVictoryNotSet();

/**
 * @dev 
 */
error DelayStartClaimVictoryGreaterThanDelayEndClaimVictoryError();

/**
 * @dev 
 */
error DelayStartGreaterThanDelayEnd();


/**
 * @dev 
 */
error DisputeExistsError();

/**
 * @dev 
 */
error DisputeParticipationNotAuthorizedError();

/**
 * @dev 
 */
error FeeDisputeNotSetError();

/**
 * @dev 
 */
error MustWaitForEndDisputePeriodError();

/**
 * @dev 
 */
error NbTeamsLimitReachedError();

/**
 * @dev 
 */
error NbPlayersPerTeamsLimitReachedError();

/**
 * @dev 
 */
error NoDisputeError();

/**
 * @dev 
 */
error NoDisputeParticipantsError();

/**
 * @dev 
 */
error NotSufficientAmountForDisputeError();

/**
 * @dev 
 */
error NotTeamMemberError();

/**
 * @dev 
 */
error NotTimeYetToParticipateToDisputeError();

/**
 * @dev 
 */
error RefundImpossibleDueToTooManyDisputeParticipantsError();

/**
 * @dev
 */
error 
RevealWinnerImpossibleDueToTooFewDisputersError();

/**
 * @dev 
 */
error SendMoneyBackToAdminError();

/**
 * @dev 
 */
error SendMoneyBackToPlayersError();

/**
 * @dev 
 */
error SendDisputeAmountBackToWinnerError();

/**
 * @dev 
 */
error TeamAlreadyClaimedVictoryError();

/**
 * @dev 
 */
error TeamDoesNotExistsError();

/**
 * @dev 
 */
error TeamDidNotClaimVictoryError();

/**
 * @dev 
 */
error TeamOfSignerAlreadyParticipatesInDisputeError();

/**
 * @dev 
 */
error TeamIsNotDisputerError();

/**
 * @dev 
 */
error TimeElapsedToJoinTeamError();

/**
 * @dev 
 */
error TimeElapsedForDisputeParticipationError();

/**
 * @dev 
 */
error TimeElapsedToClaimVictoryError();

/**
 * @dev 
 */
error TimeTooSoonToClaimVictoryError();

/**
 * @dev 
 */
error TimeElapsedToUnclaimVictoryError();

/**
 * @dev 
 */
error UnclaimVictoryNotAuthorized();

/**
 * @dev 
 */
error WinnerNotRevealedYetError();
/**
 * @dev 
 */
error WithdrawPoolNotAuthorized();

/**
 * @dev 
 */
error WithdrawPoolByLooserTeamImpossibleError();