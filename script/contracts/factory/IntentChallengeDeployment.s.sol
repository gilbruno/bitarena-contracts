// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {BitarenaFactory} from "../../../src/BitarenaFactory.sol";

contract IntentChallengeDeployment is Script {
    function run(string memory game,
        string memory platform,
        uint16 nbTeams,
        uint16 nbPlayers,
        uint256 amount,
        uint256 startTime,
        bool isPrivate) external {
        uint256 creatorPrivateKey = vm.envUint("PRIVATE_KEY_CREATOR_CHALLENGE");
        address FACTORY_ADDRESS = vm.envAddress("ADDRESS_LAST_DEPLOYED_FACTORY");       
        
        vm.startBroadcast(creatorPrivateKey);
        
        BitarenaFactory(FACTORY_ADDRESS).intentChallengeDeployment{value: amount}(
            game,
            platform,
            nbTeams,
            nbPlayers,
            amount,
            startTime,
            isPrivate
        );
        
        vm.stopBroadcast();
    }
}