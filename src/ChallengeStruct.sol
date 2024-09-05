// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

struct Challenge {
    address challengeCreator;
    address challengeAddress;
    string challengeName;
    string game;
    string platform;
    uint16 nbTeams;
    uint16 nbTeamPlayers;
    uint amountPerPlayer;
    uint startAt;
    bool isPrivate;
}   
