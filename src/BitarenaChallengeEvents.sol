// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;


event TeamCreated(uint16 indexed teamIndex);

event PlayerJoinsTeam(uint16 indexed teamIndex, address player);

event Debug(address indexed signer);

event VictoryClaimed(uint16 teamNumber, address claimer);

event VictoryUnclaimed(uint16 teamNumber, address claimer);

event DisputeAccepted(address player);

event ParticipateToDispute(address indexed player);

event PoolChallengeWithdrawed(uint16 indexed teamIndex, address indexed signer);

event RevealWinner(uint16 indexed winnerTeam, address indexed signer);