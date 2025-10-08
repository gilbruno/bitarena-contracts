// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {BitarenaFactory} from "../src/BitarenaFactory.sol";
import {BitarenaChallenge} from "../src/BitarenaChallenge.sol";
import {BitarenaGames} from "../src/BitarenaGames.sol";
import {BitarenaChallengesData} from "../src/BitarenaChallengesData.sol";
import {IBitarenaFactory} from "../src/interfaces/IBitarenaFactory.sol";
import {IBitarenaChallengesData} from "../src/interfaces/IBitarenaChallengesData.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract SimpleTreasuryTest is Test {
    // Test addresses
    address constant ADMIN_GAMES = address(0x1);
    address constant ADMIN_FACTORY = address(0x2);
    address constant ADMIN_CHALLENGE1 = address(0x3);
    address constant ADMIN_DISPUTE_CHALLENGE1 = address(0x4);
    address constant ADMIN_CHALLENGE_EMERGENCY = address(0x5);
    address constant SUPER_ADMIN_CHALLENGES_DATA = address(0x6);
    address constant PLAYER1 = address(0x7);
    address constant PLAYER2 = address(0x8);
    
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
    
    function testTreasuryWalletsAreCorrectlySet() public view {
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
    }
    
    function testNewDistributionLogic() public view {
        // Test new distribution logic (50% main treasury + 50% equally among 6 team wallets)
        address mainTreasury = bitarenaFactory.getMainTreasuryWallet();
        address[] memory teamWallets = bitarenaFactory.getTeamWallets();
        
        // Verify main treasury is correct
        assertEq(mainTreasury, MAIN_TREASURY_WALLET, "Main treasury should be correct");
        
        // Verify team wallets are correct
        assertEq(teamWallets.length, 6, "Should have 6 team wallets");
        assertEq(teamWallets[0], TEAM_WALLET_1, "Team wallet 1 should be correct");
        assertEq(teamWallets[1], TEAM_WALLET_2, "Team wallet 2 should be correct");
        assertEq(teamWallets[2], TEAM_WALLET_3, "Team wallet 3 should be correct");
        assertEq(teamWallets[3], TEAM_WALLET_4, "Team wallet 4 should be correct");
        assertEq(teamWallets[4], TEAM_WALLET_5, "Team wallet 5 should be correct");
        assertEq(teamWallets[5], TEAM_WALLET_6, "Team wallet 6 should be correct");
        
        // Test individual team wallet getters
        for (uint256 i = 0; i < 6; i++) {
            assertEq(bitarenaFactory.getTeamWalletByIndex(i), teamWallets[i], "Team wallet getter should work");
        }
        
        console.log("New distribution logic test passed");
    }
}
