// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ChallengeParams} from "../struct/ChallengeParams.sol";

interface IBitarenaChallenge {
    // External functions
    function getNbTeams() external view returns (uint16);
    function getNbTeamPlayers() external view returns (uint16);
    function getChallengeStartDate() external view returns (uint256);
    function getChallengeVisibility() external view returns (bool);
    function getAmountPerPlayer() external view returns (uint256);
    function getTeamCounter() external view returns (uint16);
    function getTeamsByTeamIndex(uint16 _teamIndex) external view returns (address[] memory);
    function getDelayStartDisputeParticipation() external view returns (uint256);
    function getDelayEndDisputeParticipation() external view returns (uint256);
    function getFeePercentageDispute() external view returns (uint16);
    function getDisputePool() external view returns (uint256);

    // Public functions
    function createOrJoinTeam(uint16 _teamIndex) external payable;
    function claimVictory() external;
    function participateToDispute() external payable;
    function pause() external;
    function unpause() external;
    function setDelayStartForVictoryClaim(uint256 _delayStartVictoryClaim) external;
    function setDelayEndForVictoryClaim(uint256 _delayEndVictoryClaim) external;
    function setDelayStartDisputeParticipation(uint256 _delayStartDisputeParticipation) external;
    function setDelayEndDisputeParticipation(uint256 _delayEndDisputeParticipation) external;
    function cancelChallenge() external;
    function setFeePercentageDispute(uint16 _percentage) external;
    function setFeePercentage(uint16 _percentage) external;
    function revealWinnerAfterDispute(uint16 _teamIndex) external;
    function withdrawChallengePool() external;
    function withdrawPoolIfNoOthersTeamsJoined() external;

    // Public view functions
    function getCreator() external view returns (address);
    function getGame() external view returns (string memory);
    function getPlatform() external view returns (string memory);
    function getIsCanceled() external view returns (bool);
    function getIsPoolWithdrawed() external view returns (bool);
    function getTeamOfPlayer(address _player) external view returns (uint16);
    function getDelayStartVictoryClaim() external view returns (uint256);
    function getDelayEndVictoryClaim() external view returns (uint256);
    function getChallengePool() external view returns (uint256);
    function getDisputeAmountParticipation() external view returns (uint256);
    function getFeePercentage() external view returns (uint16);
    function getChallengeAdmin() external view returns (address);
    function getDisputeAdmin() external view returns (address);
    function getDisputeParticipantsCount() external view returns (uint256);
    function getDisputeParticipants(uint16 _teamIndex) external view returns (address);
    function getWinnerClaimed(uint16 _teamIndex) external view returns (bool);
    function getWinnersClaimedCount() external view returns (uint256);
    function getWinnerTeam() external view returns (uint16);
    function atLeast2TeamsClaimVictory() external view returns (bool);
    function atLeast2TeamsParticipateToDispute() external view returns (bool);
    function atLeast1TeamParticipateToDispute() external view returns (bool);
    function calculateFeeAmount() external view returns (uint256);
    function calculatePoolAmountToSendBackForWinnerTeam() external view returns (uint256);

    event TeamCreated(uint16 indexed teamIndex);
    event PlayerJoinsTeam(uint16 indexed teamIndex, address player);
    event Debug(address indexed signer);
    event VictoryClaimed(uint16 teamNumber, address claimer);
    event VictoryUnclaimed(uint16 teamNumber, address claimer);
    event DisputeAccepted(address player);
    event ParticipateToDispute(address indexed player);
    event PoolChallengeWithdrawed(uint16 indexed teamIndex, address indexed signer);
    event RevealWinner(uint16 indexed winnerTeam, address indexed signer);
    event DelayStartForVictoryClaimUpdated(uint256 delayStart);
    event DelayEndForVictoryClaimUpdated(uint256 delayEnd);
    event DelayStartDisputeParticipationUpdated(uint256 delayStart);
    event DelayEndDisputeParticipationUpdated(uint256 delayEnd);
    event ChallengeCanceled(address indexed challenge);
    event FeePercentageDisputeUpdated(uint16 percentage);
    event FeePercentageUpdated(uint16 percentage);
    event FeeDistributedToTreasury(address indexed treasuryWallet, uint256 amount, uint256 challengeIndex, uint256 treasuryIndex);
    
    // Errors
    error BalanceChallengePlayerError();
    error ChallengeCanceledError();
    error ChallengeCancelAfterStartDateError();
    error ChallengePoolAlreadyWithdrawed();
    error ClaimVictoryNotAuthorized();
    error DelayClaimVictoryNotSet();
    error DelayUnclaimVictoryNotSet();
    error DelayStartClaimVictoryGreaterThanDelayEndClaimVictoryError();
    error DelayStartGreaterThanDelayEnd();
    error DisputeExistsError();
    error DisputeParticipationNotAuthorizedError();
    error FeeDisputeNotSetError();
    error MustWaitForEndDisputePeriodError();
    error NbTeamsLimitReachedError();
    error NbPlayersPerTeamsLimitReachedError();
    error NoDisputeError();
    error NoDisputeParticipantsError();
    error NotSufficientAmountForDisputeError();
    error NotTeamMemberError();
    error NotTimeYetToParticipateToDisputeError();
    error RefundImpossibleDueToTooManyDisputeParticipantsError();
    error RevealWinnerImpossibleDueToTooFewDisputersError();
    error SendMoneyBackToAdminError();
    error SendMoneyBackToPlayersError();
    error SendDisputeAmountBackToWinnerError();
    error TeamAlreadyClaimedVictoryError();
    error TeamDoesNotExistsError();
    error TeamDidNotClaimVictoryError();
    error TeamOfSignerAlreadyParticipatesInDisputeError();
    error TeamIsNotDisputerError();
    error TimeElapsedToJoinTeamError();
    error TimeElapsedForDisputeParticipationError();
    error TimeElapsedToClaimVictoryError();
    error TimeTooSoonToClaimVictoryError();
    error TimeElapsedToUnclaimVictoryError();
    error UnclaimVictoryNotAuthorized();
    error WinnerNotRevealedYetError();
    error WithdrawPoolNotAuthorized();
    error WithdrawPoolByLooserTeamImpossibleError();
    error RoleGrantFailed();
    error OtherTeamsJoinedChallengeError();
    error TimeToJoinChallengeNotElapsedError();
    error OnlyCreatorTeamCanWithdrawError();
    error TreasuryWalletNotFoundError();
    error FeeDistributionFailedError();
    error TreasuryWalletsNotConfiguredError();
} 