// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {BitarenaFactory} from "../src/BitarenaFactory.sol";
import {DeployBitarenaGames} from "./DeployBitarenaGames.s.sol";
import {BitarenaGames} from "../src/BitarenaGames.sol";

contract DeployBitarenaFactory is Script {
    function setUp() public {}

    function run() public returns (BitarenaFactory) {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ADMIN_FACTORY");
        address addressBitarenaGames = vm.envAddress("ADDRESS_LAST_DEPLOYED_GAMES");
        address adminChallenge = vm.envAddress("PUBLIC_KEY_ADMIN_CHALLENGE");
        address adminDisputeChallenge = vm.envAddress("PUBLIC_KEY_ADMIN_DISPUTE_CHALLENGE");

        vm.startBroadcast(deployerPrivateKey);
        BitarenaFactory bitarenaFactory = new BitarenaFactory(addressBitarenaGames, adminChallenge, adminDisputeChallenge);
        vm.stopBroadcast();

        console.log("BitarenaFactory deployed to address:", address(bitarenaFactory));

        return bitarenaFactory;
    }
}
