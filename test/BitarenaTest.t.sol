// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BitarenaFactory} from "../src/BitarenaFactory.sol";
import {BitarenaToken} from "../src/BitarenaToken.sol";

contract BitarenaTest is Test {
    BitarenaFactory public bitarenaFactory;
    address ADMIN_FACTORY = makeAddr("adminFactory");
    address ADMIN_CHALLENGE1 = makeAddr("adminChallenge1");
    address ADMIN_CHALLENGE2 = makeAddr("adminChallenge2");
    address ADMIN_LITIGATION_CHALLENGE1 = makeAddr("adminLitigationChallenge1");
    address ADMIN_LITIGATION_CHALLENGE2 = makeAddr("adminLitigationChallenge2");
    address CREATOR_CHALLENGE1 = makeAddr("creatorChallenge1");
    address CREATOR_CHALLENGE2 = makeAddr("creatorChallenge2");
    string CHALLENGE1 = "Challenge 1";
    string CHALLENGE2 = "Challenge 2";
    string GAME1 = "Counter Strike";
    string GAME2 = "Far cry";
    string PLATFORM1 = "UOS";
    string PLATFORM2 = "Steam";
    uint16 ONE_TEAM = 1;
    uint16 TWO_TEAMS = 2;
    uint16 ONE_PLAYER = 1;
    uint16 TWO_PLAYERS = 2;
    uint16 THREE_PLAYERS = 3;
    uint AMOUNT_PER_PLAYER = 1 ether;


    uint256 private constant STARTING_BALANCE_ETH = 10 ether; 

    function setUp() public {
        BitarenaToken bitarenaToken = new BitarenaToken();

        vm.deal(CREATOR_CHALLENGE1, STARTING_BALANCE_ETH);
        vm.deal(CREATOR_CHALLENGE2, STARTING_BALANCE_ETH);
    }

    function deployFactory() public {
        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory = new BitarenaFactory();
        vm.stopBroadcast();
    }

    function testIntentChallengeCreation1() public {
        deployFactory();
        vm.startBroadcast(CREATOR_CHALLENGE1);
        bitarenaFactory.intentChallengeCreation{value: AMOUNT_PER_PLAYER}(
            CHALLENGE1,
            GAME1,
            PLATFORM1,
            TWO_TEAMS,
            ONE_PLAYER,
            AMOUNT_PER_PLAYER,
            block.timestamp + 10 hours,
            false
        );
        vm.stopBroadcast();
    }

}
