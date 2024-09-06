// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

/**
 * @dev Emitted when a challenge is created
 */
event ChallengeDeployed(uint indexed challengeCounter, address indexed challengeAddress, address indexed challengeFactoryAddress);

/**
 * @dev Emitted when there is an intent challenge creation
 */
event IntentChallengeCreation(uint indexed challengeCounter);
