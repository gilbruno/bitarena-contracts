// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {IBitarenaChallengesData} from "../../src/interfaces/IBitarenaChallengesData.sol";

contract AuthorizeContract is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ADMIN_CHALLENGES_DATA");
        address PROXY_ADDRESS = 0x7c1F4740Bef719D63d7d97dc4d0DF8DF56443723;
        address TARGET_CONTRACT = 0xDFfB1E5746017BdF41f2dFDCf0AC39e08247b2AF;

        vm.startBroadcast(deployerPrivateKey);
        IBitarenaChallengesData(PROXY_ADDRESS).authorizeConractsRegistering(TARGET_CONTRACT);
        vm.stopBroadcast();
    }
}