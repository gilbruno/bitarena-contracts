// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

struct ChallengeParams {
    address factory;
    address challengesData;
    address challengeAdmin;
    address challengeDisputeAdmin;
    address challengeEmergencyAdmin;
    address challengeCreator;
    string game;
    string platform;
    uint16 nbTeams;
    uint16 nbTeamPlayers;
    uint256 amountPerPlayer;
    uint256 startAt;
    bool isPrivate;
}