pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {BitarenaChallenge} from "../src/BitarenaChallenge.sol";
import {ChallengeParams} from "../src/ChallengeParams.sol";

contract MockFailingReceiver {
    receive() external payable {
        revert("Intentional Failure when receive money");
    }
}