// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";

contract DeployBitarenaFactory is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        vm.stopBroadcast();
    }
}
