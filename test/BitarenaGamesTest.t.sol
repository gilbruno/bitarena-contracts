// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {BitarenaGames} from "../src/BitarenaGames.sol";
import {GAMES_ADMIN_ROLE} from "../src/BitarenaChallengeConstants.sol";

contract BitarenaGamesTest is Test {
    BitarenaGames public bitarenaGames;
    address public admin;
    address public user;

    function setUp() public {
        admin = makeAddr("admin");
        user = makeAddr("user");
        bitarenaGames = new BitarenaGames(admin);
    }

    function test_InitialSetup() public {
        assertTrue(bitarenaGames.hasRole(GAMES_ADMIN_ROLE, admin));
        assertEq(bitarenaGames.getAdmins()[0], admin);
    }

    function test_SetMode() public {
        vm.startPrank(admin);
        
        bitarenaGames.setMode("1-1");
        bitarenaGames.setMode("2-2");
        bitarenaGames.setMode("3-3");
        
        string[] memory modes = bitarenaGames.getModes();
        assertEq(modes.length, 3);
        assertEq(modes[0], "1-1");
        assertEq(modes[1], "2-2");
        assertEq(modes[2], "3-3");
        
        vm.stopPrank();
    }

    function test_SetPlatform() public {
        vm.startPrank(admin);
        
        bitarenaGames.setPlatform("steam");
        bitarenaGames.setPlatform("ps5");
        
        string[] memory platforms = bitarenaGames.getPlatforms();
        assertEq(platforms.length, 2);
        assertEq(platforms[0], "steam");
        assertEq(platforms[1], "ps5");
        
        vm.stopPrank();
    }

    function test_SetGame() public {
        vm.startPrank(admin);
        
        bitarenaGames.setGame("fortnite");
        bitarenaGames.setGame("CSGO");
        
        string[] memory games = bitarenaGames.getGames();
        assertEq(games.length, 2);
        assertEq(games[0], "fortnite");
        assertEq(games[1], "CSGO");
        
        vm.stopPrank();
    }

    function test_SetGameSupport() public {
        vm.startPrank(admin);
        
        // Setup initial data
        bitarenaGames.setGame("fortnite");
        bitarenaGames.setPlatform("steam");
        bitarenaGames.setPlatform("ps5");
        bitarenaGames.setMode("1-1");
        bitarenaGames.setMode("2-2");
        
        // Create arrays for platforms and modes
        string[] memory platforms = new string[](2);
        platforms[0] = "steam";
        platforms[1] = "ps5";
        
        string[] memory modes = new string[](2);
        modes[0] = "1-1";
        modes[1] = "2-2";
        
        // Set game support
        bitarenaGames.setGameSupport("fortnite", platforms, modes);
        
        // Verify game support
        (string[] memory supportedPlatforms, string[] memory supportedModes) = bitarenaGames.getGameSupport("fortnite");
        
        assertEq(supportedPlatforms.length, 2);
        assertEq(supportedPlatforms[0], "steam");
        assertEq(supportedPlatforms[1], "ps5");
        
        assertEq(supportedModes.length, 2);
        assertEq(supportedModes[0], "1-1");
        assertEq(supportedModes[1], "2-2");
        
        vm.stopPrank();
    }

    function testFail_SetGameSupportNonExistentGame() public {
        vm.startPrank(admin);
        
        string[] memory platforms = new string[](1);
        platforms[0] = "steam";
        
        string[] memory modes = new string[](1);
        modes[0] = "1-1";
        
        bitarenaGames.setGameSupport("nonexistent", platforms, modes);
        
        vm.stopPrank();
    }

    function testFail_SetGameSupportNonExistentPlatform() public {
        vm.startPrank(admin);
        
        bitarenaGames.setGame("fortnite");
        
        string[] memory platforms = new string[](1);
        platforms[0] = "nonexistent";
        
        string[] memory modes = new string[](1);
        modes[0] = "1-1";
        
        bitarenaGames.setGameSupport("fortnite", platforms, modes);
        
        vm.stopPrank();
    }

    function testFail_SetGameSupportNonExistentMode() public {
        vm.startPrank(admin);
        
        bitarenaGames.setGame("fortnite");
        bitarenaGames.setPlatform("steam");
        
        string[] memory platforms = new string[](1);
        platforms[0] = "steam";
        
        string[] memory modes = new string[](1);
        modes[0] = "nonexistent";
        
        bitarenaGames.setGameSupport("fortnite", platforms, modes);
        
        vm.stopPrank();
    }

    function testFail_NonAdminSetGameSupport() public {
        vm.startPrank(user);
        
        string[] memory platforms = new string[](1);
        string[] memory modes = new string[](1);
        
        bitarenaGames.setGameSupport("fortnite", platforms, modes);
        
        vm.stopPrank();
    }
}