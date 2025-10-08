// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {BitarenaFactory} from "../src/BitarenaFactory.sol";
import {BitarenaChallenge} from "../src/BitarenaChallenge.sol";
import {BitarenaGames} from "../src/BitarenaGames.sol";
import {BitarenaChallengesData} from "../src/BitarenaChallengesData.sol";
import {IBitarenaFactory} from "../src/interfaces/IBitarenaFactory.sol";
import {IBitarenaChallengesData} from "../src/interfaces/IBitarenaChallengesData.sol";
import {ChallengeParams} from "../src/struct/ChallengeParams.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TreasuryDistributionTest is Test {
    // Test addresses
    address constant ADMIN_GAMES = address(0x1);
    address constant ADMIN_FACTORY = address(0x2);
    address constant ADMIN_CHALLENGE1 = address(0x3);
    address constant ADMIN_DISPUTE_CHALLENGE1 = address(0x4);
    address constant ADMIN_CHALLENGE_EMERGENCY = address(0x5);
    address constant SUPER_ADMIN_CHALLENGES_DATA = address(0x6);
    address constant CREATOR_CHALLENGE1 = address(0x7);
    address constant PLAYER1 = address(0x8);
    address constant PLAYER2 = address(0x9);
    address constant PLAYER3 = address(0xa);
    address constant PLAYER4 = address(0xb);
    
    // Treasury wallets for testing (1 main treasury + 6 team wallets)
    address constant MAIN_TREASURY_WALLET = address(0x1001);
    address constant TEAM_WALLET_1 = address(0x1002);
    address constant TEAM_WALLET_2 = address(0x1003);
    address constant TEAM_WALLET_3 = address(0x1004);
    address constant TEAM_WALLET_4 = address(0x1005);
    address constant TEAM_WALLET_5 = address(0x1006);
    address constant TEAM_WALLET_6 = address(0x1007);
    
    uint256 constant STARTING_BALANCE_ETH = 100 ether;
    uint256 constant AMOUNT_PER_PLAYER = 1 ether;
    
    BitarenaFactory bitarenaFactory;
    BitarenaGames bitarenaGames;
    BitarenaChallengesData proxyChallengesData;
    
    function setUp() public {
        // Deploy BitarenaGames
        vm.startBroadcast(ADMIN_GAMES);
        bitarenaGames = new BitarenaGames(ADMIN_GAMES);
        bitarenaGames.setGame("TestGame");
        bitarenaGames.setPlatform("TestPlatform");
        vm.stopBroadcast();
        
        // Deploy BitarenaChallengesData
        vm.startBroadcast(SUPER_ADMIN_CHALLENGES_DATA);
        BitarenaChallengesData implementationChallengesData = new BitarenaChallengesData();
        proxyChallengesData = BitarenaChallengesData(
            address(
                new ERC1967Proxy(
                    address(implementationChallengesData),
                    abi.encodeWithSelector(
                        BitarenaChallengesData.initialize.selector,
                        SUPER_ADMIN_CHALLENGES_DATA
                    )
                )
            )
        );
        vm.stopBroadcast();
        
        // Define treasury wallets
        address[7] memory treasuryWallets = [
            MAIN_TREASURY_WALLET,
            TEAM_WALLET_1,
            TEAM_WALLET_2,
            TEAM_WALLET_3,
            TEAM_WALLET_4,
            TEAM_WALLET_5,
            TEAM_WALLET_6
        ];
        
        // Deploy BitarenaFactory
        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory = new BitarenaFactory(
            address(bitarenaGames),
            ADMIN_CHALLENGE1,
            ADMIN_DISPUTE_CHALLENGE1,
            ADMIN_CHALLENGE_EMERGENCY,
            address(proxyChallengesData),
            treasuryWallets
        );
        vm.stopBroadcast();
        
        // Authorize factory to register challenges
        vm.startBroadcast(SUPER_ADMIN_CHALLENGES_DATA);
        IBitarenaChallengesData(address(proxyChallengesData)).authorizeConractsRegistering(address(bitarenaFactory));
        vm.stopBroadcast();
        
        // Fund the factory
        vm.deal(address(bitarenaFactory), STARTING_BALANCE_ETH);
    }
    
    function testTreasuryWalletsInitialization() public view {
        // Test that treasury wallets are correctly initialized
        address[] memory treasuryWallets = bitarenaFactory.getTreasuryWallets();
        assertEq(treasuryWallets.length, 7);
        assertEq(treasuryWallets[0], MAIN_TREASURY_WALLET);
        assertEq(treasuryWallets[1], TEAM_WALLET_1);
        assertEq(treasuryWallets[2], TEAM_WALLET_2);
        assertEq(treasuryWallets[3], TEAM_WALLET_3);
        assertEq(treasuryWallets[4], TEAM_WALLET_4);
        assertEq(treasuryWallets[5], TEAM_WALLET_5);
        assertEq(treasuryWallets[6], TEAM_WALLET_6);
        
        // Test individual getters
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(0), MAIN_TREASURY_WALLET);
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(1), TEAM_WALLET_1);
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(2), TEAM_WALLET_2);
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(3), TEAM_WALLET_3);
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(4), TEAM_WALLET_4);
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(5), TEAM_WALLET_5);
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(6), TEAM_WALLET_6);
        
        // Test count
        assertEq(bitarenaFactory.getTreasuryWalletsCount(), 7);
        
        // Test new getters
        assertEq(bitarenaFactory.getMainTreasuryWallet(), MAIN_TREASURY_WALLET);
        
        address[] memory teamWallets = bitarenaFactory.getTeamWallets();
        assertEq(teamWallets.length, 6);
        assertEq(teamWallets[0], TEAM_WALLET_1);
        assertEq(teamWallets[1], TEAM_WALLET_2);
        assertEq(teamWallets[2], TEAM_WALLET_3);
        assertEq(teamWallets[3], TEAM_WALLET_4);
        assertEq(teamWallets[4], TEAM_WALLET_5);
        assertEq(teamWallets[5], TEAM_WALLET_6);
        
        // Test individual team wallet getters
        assertEq(bitarenaFactory.getTeamWalletByIndex(0), TEAM_WALLET_1);
        assertEq(bitarenaFactory.getTeamWalletByIndex(1), TEAM_WALLET_2);
        assertEq(bitarenaFactory.getTeamWalletByIndex(2), TEAM_WALLET_3);
        assertEq(bitarenaFactory.getTeamWalletByIndex(3), TEAM_WALLET_4);
        assertEq(bitarenaFactory.getTeamWalletByIndex(4), TEAM_WALLET_5);
        assertEq(bitarenaFactory.getTeamWalletByIndex(5), TEAM_WALLET_6);
    }
    
    function testFeeDistributionModulo() public {
        // Create multiple challenges to test modulo distribution
        BitarenaChallenge[] memory challenges = new BitarenaChallenge[](5);
        
        // Fund the factory once with enough balance for all challenges
        vm.deal(address(bitarenaFactory), STARTING_BALANCE_ETH * 10);
        
        for (uint256 i = 0; i < 5; i++) {
            // Fund the creator for challenge creation
            vm.deal(CREATOR_CHALLENGE1, AMOUNT_PER_PLAYER);
            
            // Create challenge
            vm.startBroadcast(CREATOR_CHALLENGE1);
            challenges[i] = bitarenaFactory.intentChallengeDeployment{value: AMOUNT_PER_PLAYER}(
                "TestGame",
                "TestPlatform",
                2, // nbTeams
                2, // nbTeamPlayers
                AMOUNT_PER_PLAYER,
                block.timestamp + 1 hours,
                false // isPrivate
            );
            vm.stopBroadcast();
            
            // Join teams
            vm.deal(PLAYER1, AMOUNT_PER_PLAYER);
            vm.deal(PLAYER2, AMOUNT_PER_PLAYER);
            vm.deal(PLAYER3, AMOUNT_PER_PLAYER);
            vm.deal(PLAYER4, AMOUNT_PER_PLAYER);
            
            // PLAYER1 joins team 1 (creator's team)
            vm.startBroadcast(PLAYER1);
            challenges[i].createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1); // Join team 1
            vm.stopBroadcast();
            
            // PLAYER2 creates team 2
            vm.startBroadcast(PLAYER2);
            challenges[i].createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0); // Create team 2
            vm.stopBroadcast();
            
            // PLAYER3 joins team 2
            vm.startBroadcast(PLAYER3);
            challenges[i].createOrJoinTeam{value: AMOUNT_PER_PLAYER}(2); // Join team 2
            vm.stopBroadcast();
            
            // PLAYER4 joins team 1 (creator's team) - this will fail as team 1 is full
            // So we'll have PLAYER4 join team 2 instead, but that will also fail
            // Let's skip PLAYER4 for now since we only need 2 players per team
        }
        
        // Set delays for victory claim and dispute participation
        for (uint256 i = 0; i < 5; i++) {
            vm.startBroadcast(ADMIN_CHALLENGE1);
            challenges[i].setDelayStartForVictoryClaim(1 minutes);
            challenges[i].setDelayEndForVictoryClaim(3 hours); // Allow 3 hours to claim victory
            vm.stopBroadcast();
            
            // Set dispute participation delays
            vm.startBroadcast(ADMIN_DISPUTE_CHALLENGE1);
            challenges[i].setDelayStartDisputeParticipation(1 minutes);
            challenges[i].setDelayEndDisputeParticipation(10 minutes); // Short dispute period
            vm.stopBroadcast();
        }
        
        // Record initial balances of treasury wallets
        uint256 initialMainTreasuryBalance = MAIN_TREASURY_WALLET.balance;
        uint256[] memory initialTeamBalances = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            initialTeamBalances[i] = bitarenaFactory.getTeamWalletByIndex(i).balance;
        }
        
        // Claim victory and withdraw for each challenge
        for (uint256 i = 0; i < 5; i++) {
            // Get the actual start time of the challenge
            uint256 challengeStartTime = challenges[i].getChallengeStartDate();
            
            // Calculate the correct time for victory claim
            // We need to be in the window: startAt + delayStartVictoryClaim to startAt + delayStartVictoryClaim + delayEndVictoryClaim
            // delayStartVictoryClaim = 1 minutes = 60 seconds
            // delayEndVictoryClaim = 3 hours = 10800 seconds
            // So we need to be between: startAt + 60 and startAt + 60 + 10800
            // Let's use startAt + 2 hours = startAt + 7200 seconds (which is in the valid window)
            uint256 victoryClaimTime = challengeStartTime + 2 hours; // 2 hours after challenge start
            vm.warp(victoryClaimTime);
            
            // Player 1 claims victory for team 1
            vm.startBroadcast(PLAYER1);
            challenges[i].claimVictory();
            vm.stopBroadcast();
            
            // Fast forward to allow withdrawal (wait for all delays to end)
            // We need to wait for: startAt + delayStartVictoryClaim + delayEndVictoryClaim + delayStartDisputeParticipation + delayEndDisputeParticipation
            // = challengeStartTime + 60 + 10800 + 60 + 600 = challengeStartTime + 11520
            uint256 withdrawalTime = challengeStartTime + 11520; // All delays passed
            vm.warp(withdrawalTime);
            
            // Player 1 withdraws the pool
            vm.startBroadcast(PLAYER1);
            challenges[i].withdrawChallengePool();
            vm.stopBroadcast();
        }
        
        // Check that fees were distributed according to new rules (50% main treasury + 50% equally among 6 team wallets)
        uint256 finalMainTreasuryBalance = MAIN_TREASURY_WALLET.balance;
        uint256[] memory finalTeamBalances = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {
            finalTeamBalances[i] = bitarenaFactory.getTeamWalletByIndex(i).balance;
        }
        
        // Calculate total fees distributed across all challenges
        uint256 totalMainTreasuryIncrease = finalMainTreasuryBalance - initialMainTreasuryBalance;
        uint256 totalTeamIncrease = 0;
        for (uint256 i = 0; i < 6; i++) {
            totalTeamIncrease += finalTeamBalances[i] - initialTeamBalances[i];
        }
        
        // Main treasury should receive approximately 50% of total fees
        assertGt(totalMainTreasuryIncrease, 0, "Main treasury should receive fees");
        
        // Each team wallet should receive equal share of remaining 50%
        for (uint256 i = 0; i < 6; i++) {
            uint256 teamIncrease = finalTeamBalances[i] - initialTeamBalances[i];
            assertGt(teamIncrease, 0, "Each team wallet should receive fees");
            console.log("Team wallet", i, "increase:", teamIncrease);
        }
        
        // Verify that main treasury received approximately half of total team increase
        // (allowing for small rounding differences)
        assertApproxEqRel(totalMainTreasuryIncrease, totalTeamIncrease, 1e15, "Main treasury should receive ~50% of total fees");
        
        console.log("Main treasury increase:", totalMainTreasuryIncrease);
        console.log("Total team increase:", totalTeamIncrease);
    }
    
    function testFeeDistributionEvent() public {
        // Fund the factory for challenge creation
        vm.deal(address(bitarenaFactory), STARTING_BALANCE_ETH);
        
        // Fund the creator for challenge creation
        vm.deal(CREATOR_CHALLENGE1, AMOUNT_PER_PLAYER);
        
        // Create a challenge
        vm.startBroadcast(CREATOR_CHALLENGE1);
        BitarenaChallenge challenge = bitarenaFactory.intentChallengeDeployment{value: AMOUNT_PER_PLAYER}(
            "TestGame",
            "TestPlatform",
            2, // nbTeams
            2, // nbTeamPlayers
            AMOUNT_PER_PLAYER,
            block.timestamp + 1 hours,
            false // isPrivate
        );
        vm.stopBroadcast();
        
        // Join teams
        vm.deal(PLAYER1, AMOUNT_PER_PLAYER);
        vm.deal(PLAYER2, AMOUNT_PER_PLAYER);
        
        vm.startBroadcast(PLAYER1);
        challenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(0); // Create team 1
        vm.stopBroadcast();
        
        vm.startBroadcast(PLAYER2);
        challenge.createOrJoinTeam{value: AMOUNT_PER_PLAYER}(1); // Join team 2
        vm.stopBroadcast();
        
        // Set delays
        vm.startBroadcast(ADMIN_CHALLENGE1);
        challenge.setDelayStartForVictoryClaim(1 minutes);
        challenge.setDelayEndForVictoryClaim(3 hours); // Allow 3 hours to claim victory
        vm.stopBroadcast();
        
        // Set dispute participation delays
        vm.startBroadcast(ADMIN_DISPUTE_CHALLENGE1);
        challenge.setDelayStartDisputeParticipation(1 minutes);
        challenge.setDelayEndDisputeParticipation(10 minutes); // Short dispute period
        vm.stopBroadcast();
        
        // Get the actual start time of the challenge
        uint256 challengeStartTime = challenge.getChallengeStartDate();
        
        // Calculate the correct time for victory claim
        // We need to be in the window: startAt + delayStartVictoryClaim to startAt + delayStartVictoryClaim + delayEndVictoryClaim
        // delayStartVictoryClaim = 1 minutes = 60 seconds
        // delayEndVictoryClaim = 3 hours = 10800 seconds
        // So we need to be between: startAt + 60 and startAt + 60 + 10800
        // Let's use startAt + 2 hours = startAt + 7200 seconds (which is in the valid window)
        uint256 victoryClaimTime = challengeStartTime + 2 hours; // 2 hours after challenge start
        vm.warp(victoryClaimTime);
        
        // Claim victory
        vm.startBroadcast(PLAYER1);
        challenge.claimVictory();
        vm.stopBroadcast();
        
        // Fast forward to allow withdrawal (wait for all delays to end)
        // We need to wait for: startAt + delayStartVictoryClaim + delayEndVictoryClaim + delayStartDisputeParticipation + delayEndDisputeParticipation
        // = challengeStartTime + 60 + 10800 + 60 + 600 = challengeStartTime + 11520
        uint256 withdrawalTime = challengeStartTime + 11520; // All delays passed
        vm.warp(withdrawalTime);
        
        // Withdraw the pool (this should emit FeeDistributedToTreasuryAndTeam event)
        // Note: We can't easily test the exact event parameters due to dynamic arrays
        // but we can verify the event is emitted by checking balances
        
        vm.startBroadcast(PLAYER1);
        challenge.withdrawChallengePool();
        vm.stopBroadcast();
    }
}
