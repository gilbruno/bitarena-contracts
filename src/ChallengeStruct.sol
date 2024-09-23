// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

struct Challenge {
    address challengeCreator;
    address challengeAddress;
    bytes32 game;
    bytes32 platform;
    uint16 nbTeams;
    uint16 nbTeamPlayers;
    uint amountPerPlayer;
    uint startAt;
    bool isPrivate;
}   
