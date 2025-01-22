//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BitarenaDeploymentKeys} from "./BitarenaDeploymentKeys.sol";
import {BitarenaGames} from "../../src/BitarenaGames.sol";
import {BitarenaFactory} from "../../src/BitarenaFactory.sol";
import {BitarenaChallengesData} from "../../src/BitarenaChallengesData.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
/**
 * @title Deploy All contracts
 * @author 
 * @notice 
 */
contract DeployScript is Script {
  function run() external {

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ADMIN_FACTORY");
    vm.startBroadcast(deployerPrivateKey);

    // BitarenaGames
    address firstAdminGames = BitarenaDeploymentKeys.ADMIN_BITARENA_GAMES;
    
    // BitarenaChallenge
    address challengeAdmin = BitarenaDeploymentKeys.CHALLENGE_ADMIN;
    address challengeDisputeAdmin = BitarenaDeploymentKeys.CHALLENGE_DISPUTE_ADMIN;
    address challengeEmergencyAdmin = BitarenaDeploymentKeys.CHALLENGE_EMERGENCY_ADMIN;


    //******************************************************************/
    // ********** 1 - Deploy BitarenaGames ****************/
    //******************************************************************/
    BitarenaGames bitarenaGames = new BitarenaGames(firstAdminGames);
    console.log("BitarenaGames deployed to %s", address(bitarenaGames));

    //******************************************************************/
    // ********** 2 - Deploy BitarenaChallengesData ****************/
    //******************************************************************/
    // 2-1 Deploy BitarenaChallengesData implementation
    BitarenaChallengesData implementationChallengesData = new BitarenaChallengesData();
    // 2-2 Deploy BitarenaChallengesData proxy 
    ERC1967Proxy proxyChallengesData = new ERC1967Proxy(
        address(implementationChallengesData),
        abi.encodeWithSelector(
            BitarenaChallengesData.initialize.selector,
            BitarenaDeploymentKeys.SUPER_ADMIN_CHALLENGES_DATA
        )
    );

    //******************************************************************/
    //********* 3 - Deploy BitarenaFactory ****************/
    //******************************************************************/
    //   2-1. Deploy implementation
    BitarenaFactory bitarenaFactory = new BitarenaFactory(address(bitarenaGames), challengeAdmin, challengeDisputeAdmin, challengeEmergencyAdmin, address(proxyChallengesData));
    console.log("BitarenaFactory implementation deployed to %s", address(bitarenaFactory));


    vm.stopBroadcast();

  }
}
