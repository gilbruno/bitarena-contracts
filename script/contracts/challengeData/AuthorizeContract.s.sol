// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {IBitarenaChallengesData} from "../../../src/interfaces/IBitarenaChallengesData.sol";

contract AuthorizeContract is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ADMIN_CHALLENGES_DATA");
        address PROXY_ADDRESS = vm.envAddress("ADDRESS_LAST_DEPLOYED_CHALLENGES_DATA");
        address TARGET_CONTRACT = vm.envAddress("ADDRESS_LAST_DEPLOYED_FACTORY");

        vm.startBroadcast(deployerPrivateKey);
        IBitarenaChallengesData(PROXY_ADDRESS).authorizeConractsRegistering(TARGET_CONTRACT);
        vm.stopBroadcast();
    }
}