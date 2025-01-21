// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

/**
 * @title BitarenaDeploymentKeys
 * @dev Contrat de bibliothèque contenant les clés publiques et les adresses constantes pour le déploiement
 * @notice Ce contrat est utilisé comme référence centrale pour les adresses de déploiement
 */
library BitarenaDeploymentKeys {

    // TESTNET AMOY

    // 1- ADMIN GAMES
    address public constant ADMIN_BITARENA_GAMES = 0x7C2e9F2Bc26a90E74b5d0eEeB5b546864DdE1FC1;

    // 1- CHALLENGE ADMIN
    address internal constant CHALLENGE_ADMIN = 0x7C2e9F2Bc26a90E74b5d0eEeB5b546864DdE1FC1;

    // 2- CHALLENGE DISPUTE ADMIN
    address internal constant CHALLENGE_DISPUTE_ADMIN = 0x7C2e9F2Bc26a90E74b5d0eEeB5b546864DdE1FC1;

    // 3- EMERGENCY ADMIN GAMES
    address public constant CHALLENGE_EMERGENCY_ADMIN = 0x7C2e9F2Bc26a90E74b5d0eEeB5b546864DdE1FC1;

}