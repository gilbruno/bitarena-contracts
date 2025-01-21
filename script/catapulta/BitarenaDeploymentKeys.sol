// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

/**
 * @title BitarenaDeploymentKeys
 * @dev Contrat de bibliothèque contenant les clés publiques et les adresses constantes pour le déploiement
 * @notice Ce contrat est utilisé comme référence centrale pour les adresses de déploiement
 */
library BitarenaDeploymentKeys {

    // TESTNET SEPOLIA 

    // 1- ADMIN GAMES
    address public constant ADMIN_BITARENA_GAMES = 0x2376ef8eDAE449B19eB63e3635Ce27eb9282c348;

    // 1- CHALLENGE ADMIN
    address internal constant CHALLENGE_ADMIN = 0x6eEc6ed4CBD3FD4eFe75754f9bb1d49c925A4180;

    // 2- CHALLENGE DISPUTE ADMIN
    address internal constant CHALLENGE_DISPUTE_ADMIN = 0x6eEc6ed4CBD3FD4eFe75754f9bb1d49c925A4180;

    // 3- EMERGENCY ADMIN GAMES
    address public constant CHALLENGE_EMERGENCY_ADMIN = 0x2376ef8eDAE449B19eB63e3635Ce27eb9282c348;

    


}