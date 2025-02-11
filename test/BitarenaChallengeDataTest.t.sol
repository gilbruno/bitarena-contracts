// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {BitarenaChallengesData} from "../src/BitarenaChallengesData.sol";
import {IBitarenaChallengesData} from "../src/interfaces/IBitarenaChallengesData.sol";
contract BitarenaChallengesDataTest is Test {
    IBitarenaChallengesData public challengesData;
    address public admin = 0x7C2e9F2Bc26a90E74b5d0eEeB5b546864DdE1FC1;
    address public targetContract = 0xDFfB1E5746017BdF41f2dFDCf0AC39e08247b2AF;

    function setUp() public {
        // Pointer vers le contrat déployé (PROXY)
        challengesData = BitarenaChallengesData(0x7c1F4740Bef719D63d7d97dc4d0DF8DF56443723);
        // Simuler l'adresse de l'admin
        vm.startPrank(admin);
    }

    function testAuthorizeContractsRegistering() public view {
        console2.log("Admin address:", admin);
        console2.log("Target contract:", targetContract);
        
        // Log les rôles avant
        //console2.log("Has admin role before:", challengesData.hasRole(0x0000000000000000000000000000000000000000000000000000000000000000, admin));
        //console2.log("Contract authorized before:", challengesData.hasRole(0x16d8fb2e06c01ce79d33fb64c8b359c18ecd1ff13b8f60c0b3d0401e63f5e593, targetContract));
        
        // Exécuter la fonction
        // challengesData.authorizeConractsRegistering(targetContract);
        
        // Log les rôles après
        //console2.log("Contract authorized after:", challengesData.hasRole(0x16d8fb2e06c01ce79d33fb64c8b359c18ecd1ff13b8f60c0b3d0401e63f5e593, targetContract));
    }
}