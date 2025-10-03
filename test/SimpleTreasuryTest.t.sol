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
    
    // Treasury wallets for testing
    address constant TREASURY_WALLET_1 = address(0x1001);
    address constant TREASURY_WALLET_2 = address(0x1002);
    address constant TREASURY_WALLET_3 = address(0x1003);
    address constant TREASURY_WALLET_4 = address(0x1004);
    
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
        address[4] memory treasuryWallets = [
            TREASURY_WALLET_1,
            TREASURY_WALLET_2,
            TREASURY_WALLET_3,
            TREASURY_WALLET_4
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
        assertEq(treasuryWallets.length, 4);
        assertEq(treasuryWallets[0], TREASURY_WALLET_1);
        assertEq(treasuryWallets[1], TREASURY_WALLET_2);
        assertEq(treasuryWallets[2], TREASURY_WALLET_3);
        assertEq(treasuryWallets[3], TREASURY_WALLET_4);
        
        // Test individual getters
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(0), TREASURY_WALLET_1);
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(1), TREASURY_WALLET_2);
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(2), TREASURY_WALLET_3);
        assertEq(bitarenaFactory.getTreasuryWalletByIndex(3), TREASURY_WALLET_4);
        
        // Test count
        assertEq(bitarenaFactory.getTreasuryWalletsCount(), 4);
    }
    
    function testModuloCalculation() public {
        // Test modulo calculation logic
        address[] memory treasuryWallets = bitarenaFactory.getTreasuryWallets();
        uint256 treasuryWalletsCount = treasuryWallets.length;
        
        // Test different challenge indices
        assertEq(1 % treasuryWalletsCount, 1); // Challenge 1 -> Treasury 1
        assertEq(2 % treasuryWalletsCount, 2); // Challenge 2 -> Treasury 2
        assertEq(3 % treasuryWalletsCount, 3); // Challenge 3 -> Treasury 3
        assertEq(4 % treasuryWalletsCount, 0); // Challenge 4 -> Treasury 0
        assertEq(5 % treasuryWalletsCount, 1); // Challenge 5 -> Treasury 1
        
        console.log("Modulo calculation test passed");
    }
}
