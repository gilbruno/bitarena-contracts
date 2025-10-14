//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BitarenaDeploymentKeys} from "./BitarenaDeploymentKeys.sol";
import {BitarenaGames} from "../../src/BitarenaGames.sol";
import {BitarenaFactory} from "../../src/BitarenaFactory.sol";
import {BitarenaChallengesData} from "../../src/BitarenaChallengesData.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BitarenaChallenge} from "../../src/BitarenaChallenge.sol";
import {ChallengeParams} from "../../src/struct/ChallengeParams.sol";
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
    console.log("BitarenaChallengesData implementation deployed to %s", address(implementationChallengesData));
    console.log("BitarenaChallengesData proxy deployed to %s", address(proxyChallengesData));

    //******************************************************************/
    //********* 3 - Deploy BitarenaFactory ****************/
    //******************************************************************/
    // Define treasury wallets (1 main treasury + 6 team wallets for fee distribution)
    address[7] memory treasuryWallets = [
        0xe1AC37c903D42F5d7C2362c4A49Ce81703132342, // Main Treasury Wallet
        0xEeDeF819730808f1779573b9C2c210e08c16673E, // Team Wallet 1 - Gilles
        0xbee951ef3B1c4a1B37a1529203AA9237B4BDe49e, // Team Wallet 2 - Eric
        0x9cDE6f3ddc55183942f6c26D9df56cAA864fA038, // Team Wallet 3 - Greg
        0x386B167f396882be2aaE0B3B4b43771f40C85814, // Team Wallet 4 - Corentin
        0x212FDDc0771E7EcC0b36069D8BA407088094B15C, // Team Wallet 5 - François (still waiting the address )
        0x2eAE7fd035D28c225dC7645F25E355e3ca52Ea81  // Team Wallet 6 - Marc
    ];
    
    //   2-1. Deploy implementation
    BitarenaFactory bitarenaFactory = new BitarenaFactory(address(bitarenaGames), challengeAdmin, challengeDisputeAdmin, challengeEmergencyAdmin, address(proxyChallengesData), treasuryWallets);
    console.log("BitarenaFactory implementation deployed to %s", address(bitarenaFactory));

    //***********************************************************************************************/
    //********* 4 - Deploy Challenge (in order to others future challanges to be readable and verified)
    //***********************************************************************************************/
    ChallengeParams memory challengeParams = ChallengeParams({
            factory: address(bitarenaFactory),
            challengesData: address(proxyChallengesData),
            challengeAdmin: challengeAdmin,
            challengeDisputeAdmin: challengeDisputeAdmin,
            challengeEmergencyAdmin: challengeEmergencyAdmin,
            challengeCreator: challengeAdmin,
            game: "game",
            platform: "platform",
            nbTeams: 1,
            nbTeamPlayers: 1,
            amountPerPlayer: 1 ether,
            startAt: block.timestamp + 1 days,
            isPrivate: false
            });

    BitarenaChallenge challenge = new BitarenaChallenge(challengeParams);    
    console.log("Challenge deployed to %s", address(challenge));


    vm.stopBroadcast();

  }
}
