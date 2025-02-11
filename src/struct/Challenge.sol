// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

struct Challenge {
    address challengeAddress;
    address challengeCreator;
    address challengeAdmin;
    address challengeDisputeAdmin;
    string game;
    string platform;
    uint16 nbTeams;
    uint16 nbTeamPlayers;
    uint256 amountPerPlayer;
    uint256 startAt;
    bool isPrivate;
    uint256 pool;
    uint16 winnerTeam;
    uint16 winnersClaimedCount;
    uint256 delayStartVictoryClaim;
    uint256 delayEndVictoryClaim;
    uint256 delayStartDisputeParticipation;
    uint256 delayEndDisputeParticipation;
    uint256 feePercentageDispute;
}
