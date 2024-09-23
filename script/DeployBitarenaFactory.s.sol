// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {BitarenaFactory} from "../src/BitarenaFactory.sol";

contract DeployBitarenaFactory is Script {
    function setUp() public {}

    function run() public returns (BitarenaFactory) {
        vm.startBroadcast();
        BitarenaFactory bitarenaFactory = new BitarenaFactory();
        vm.stopBroadcast();
        return bitarenaFactory;
    }
}
