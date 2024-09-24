// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {ADMIN_GAMES} from "./BitarenaChallengeConstants.sol";
import {IBitarenaGames} from "./IBitarenaGames.sol";

contract BitarenaGames is Context, AccessControl, IBitarenaGames {

    address[] private s_admins;

    string[] private s_games;

    string[] private s_platforms;

    constructor() {
        _grantRole(ADMIN_GAMES, _msgSender());
    }


    function grantNewAdmin(address _newAdmin) public onlyRole(ADMIN_GAMES) {
        _grantRole(ADMIN_GAMES, _newAdmin);
        s_admins.push(_newAdmin);
    }

    function getAdmins() public view returns(address[] memory) {
        return s_admins;
    }

    function setGame(string memory _game) public onlyRole(ADMIN_GAMES) { 
        s_games.push(_game);
    }

    function setPlatform(string memory _platform) public onlyRole(ADMIN_GAMES) {
        s_platforms.push(_platform);
    }

    function getGames() public view returns (string[] memory) { 
        return s_games;
    }
    function getGameByIndex(uint256 _gameIndex) public view returns (string memory) { 
        return s_games[_gameIndex];
    }

    function getPlatforms() public view returns (string[] memory){
        return s_platforms;
    }

    function getPlatformByIndex(uint256 _platformIndex) public view returns (string memory){
        return s_platforms[_platformIndex];
    }

}
