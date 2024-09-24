// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {BitarenaGames} from "../src/BitarenaGames.sol";

contract DeployBitarenaGames is Script {
    function setUp() public {}

    function run() public returns (BitarenaGames) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ADMIN_GAMES");
        
        vm.startBroadcast(deployerPrivateKey);
        BitarenaGames bitarenaGames = new BitarenaGames();
        vm.stopBroadcast();
        return bitarenaGames;
    }
}
