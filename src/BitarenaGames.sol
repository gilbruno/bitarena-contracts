// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {AccessControlDefaultAdminRules} from "openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {ADMIN_GAMES} from "./BitarenaChallengeConstants.sol";

contract BitarenaGames is Context, AccessControlDefaultAdminRules {

    address[] private s_admins;

    string[] private s_games;

    string[] private s_platforms;

    constructor(address _adminGames) AccessControlDefaultAdminRules(1 days, _adminGames) {
        _grantRole(ADMIN_GAMES, _adminGames);
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

    function getPlatforms() public view returns (string[] memory){
        return s_platforms;
    }

}
