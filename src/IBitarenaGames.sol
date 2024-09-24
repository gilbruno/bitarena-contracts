// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

interface IBitarenaGames {
    function getGames() external view returns (string[] memory);

    function getPlatforms() external view returns (string[] memory);

}