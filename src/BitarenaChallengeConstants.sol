// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;


bytes32 constant CHALLENGE_ADMIN_ROLE = keccak256("CHALLENGE_ADMIN_ROLE");
bytes32 constant CHALLENGE_DISPUTE_ADMIN_ROLE = keccak256("CHALLENGE_DISPUTE_ADMIN_ROLE");
bytes32 constant CHALLENGE_CREATOR_ROLE = keccak256("CHALLENGE_CREATOR_ROLE");
bytes32 constant GAMER_ROLE = keccak256("GAMER_ROLE");
    
uint8 constant FEE_PERCENTAGE_AMOUNT_BY_DEFAULT = 15;
uint8 constant FEE_PERCENTAGE_DISPUTE_AMOUNT_BY_DEFAULT = 15;

uint256 constant DELAY_START_VICTORY_CLAIM_BY_DEFAULT = 1 hours; //After startAt
uint256 constant DELAY_END_VICTORY_CLAIM_BY_DEFAULT = 24 hours; //After startVictoryclaim

uint256 constant DELAY_START_DISPUTE_PARTICIPATION_BY_DEFAULT = 1 hours; //After endVictoryclaim
uint256 constant DELAY_END_DISPUTE_PARTICIPATION_BY_DEFAULT = 24 hours; //After startdisputeParticipation
