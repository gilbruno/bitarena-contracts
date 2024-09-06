// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

struct ChallengeParams {
    address factory;
    address challengeAdmin;
    address challengeLitigationAdmin;
    address challengeCreator;
    bytes32 name;
    bytes32 game;
    bytes32 platform;
    uint16 nbTeams;
    uint16 nbTeamPlayers;
    uint256 amountPerPlayer;
    uint256 startAt;
    bool isPrivate;
}