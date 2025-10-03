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

contract TreasuryErrorTest is Test {
    // Test addresses
    address constant ADMIN_GAMES = address(0x1);
    address constant ADMIN_FACTORY = address(0x2);
    address constant ADMIN_CHALLENGE1 = address(0x3);
    address constant ADMIN_DISPUTE_CHALLENGE1 = address(0x4);
    address constant ADMIN_CHALLENGE_EMERGENCY = address(0x5);
    address constant SUPER_ADMIN_CHALLENGES_DATA = address(0x6);
    address constant PLAYER1 = address(0x7);
    address constant PLAYER2 = address(0x8);
    
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
        
        // Authorize factory to register challenges
        vm.startBroadcast(SUPER_ADMIN_CHALLENGES_DATA);
        IBitarenaChallengesData(address(proxyChallengesData)).authorizeConractsRegistering(address(bitarenaFactory));
        vm.stopBroadcast();
    }
    
    function testTreasuryWalletsNotConfiguredError() public {
        // Create a factory with empty treasury wallets array
        // This should not be possible with the current constructor, but we can test the error
        // by creating a mock scenario where treasuryWalletsCount is 0
        
        // Define empty treasury wallets (this will cause an error in constructor)
        address[4] memory emptyTreasuryWallets = [
            address(0), // This should cause TreasuryWalletAddressZeroError
            address(0),
            address(0),
            address(0)
        ];
        
        // This should revert with TreasuryWalletAddressZeroError
        vm.startBroadcast(ADMIN_FACTORY);
        vm.expectRevert(abi.encodeWithSelector(IBitarenaFactory.TreasuryWalletAddressZeroError.selector));
        bitarenaFactory = new BitarenaFactory(
            address(bitarenaGames),
            ADMIN_CHALLENGE1,
            ADMIN_DISPUTE_CHALLENGE1,
            ADMIN_CHALLENGE_EMERGENCY,
            address(proxyChallengesData),
            emptyTreasuryWallets
        );
        vm.stopBroadcast();
    }
    
    function testTreasuryWalletsValidation() public {
        // Test that treasury wallets must be non-zero addresses
        address[4] memory invalidTreasuryWallets = [
            address(0x1001), // Valid
            address(0),      // Invalid - should cause error
            address(0x1003), // Valid
            address(0x1004)  // Valid
        ];
        
        vm.startBroadcast(ADMIN_FACTORY);
        vm.expectRevert(abi.encodeWithSelector(IBitarenaFactory.TreasuryWalletAddressZeroError.selector));
        bitarenaFactory = new BitarenaFactory(
            address(bitarenaGames),
            ADMIN_CHALLENGE1,
            ADMIN_DISPUTE_CHALLENGE1,
            ADMIN_CHALLENGE_EMERGENCY,
            address(proxyChallengesData),
            invalidTreasuryWallets
        );
        vm.stopBroadcast();
    }
    
    function testValidTreasuryWallets() public {
        // Test with valid treasury wallets
        address[4] memory validTreasuryWallets = [
            address(0x1001),
            address(0x1002),
            address(0x1003),
            address(0x1004)
        ];
        
        vm.startBroadcast(ADMIN_FACTORY);
        bitarenaFactory = new BitarenaFactory(
            address(bitarenaGames),
            ADMIN_CHALLENGE1,
            ADMIN_DISPUTE_CHALLENGE1,
            ADMIN_CHALLENGE_EMERGENCY,
            address(proxyChallengesData),
            validTreasuryWallets
        );
        vm.stopBroadcast();
        
        // Verify treasury wallets are correctly set
        address[] memory treasuryWallets = bitarenaFactory.getTreasuryWallets();
        assertEq(treasuryWallets.length, 4);
        assertEq(treasuryWallets[0], address(0x1001));
        assertEq(treasuryWallets[1], address(0x1002));
        assertEq(treasuryWallets[2], address(0x1003));
        assertEq(treasuryWallets[3], address(0x1004));
        
        console.log("Valid treasury wallets test passed");
    }
}
