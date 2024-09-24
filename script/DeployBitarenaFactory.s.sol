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

        DeployBitarenaGames deployBitarenaGames = new DeployBitarenaGames();
        BitarenaGames bitarenaGames = deployBitarenaGames.run();

        vm.startBroadcast(deployerPrivateKey);
        BitarenaFactory bitarenaFactory = new BitarenaFactory(address(bitarenaGames));
        vm.stopBroadcast();

        console.log("BitarenaGames deployed to address:", address(bitarenaGames));
        console.log("BitarenaFactory deployed to address:", address(bitarenaFactory));

        return bitarenaFactory;
    }
}
