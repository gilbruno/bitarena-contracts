// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";
import {GAMES_ADMIN_ROLE} from "./BitarenaChallengeConstants.sol";
import {IBitarenaGames} from "./interfaces/IBitarenaGames.sol";


contract BitarenaGames is Context, AccessControl, IBitarenaGames {

    address[] private s_admins;

    string[] private s_games;

    string[] private s_platforms;

    constructor(address _adminGames) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(GAMES_ADMIN_ROLE, _adminGames);
        s_admins.push(_adminGames);
    }


    modifier gameNotExists(string memory _game) {
        for(uint i = 0; i < s_games.length; i++) {
            if(keccak256(bytes(s_games[i])) == keccak256(bytes(_game))) {
                revert GameAlreadyExists(_game);
            }
        }
        _;
    }

    modifier platformNotExists(string memory _platform) {
        for(uint i = 0; i < s_platforms.length; i++) {
            if(keccak256(bytes(s_platforms[i])) == keccak256(bytes(_platform))) {
                revert PlatformAlreadyExists(_platform);
            }
        }
        _;
    }

    function grantNewAdmin(address _newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GAMES_ADMIN_ROLE, _newAdmin);
        s_admins.push(_newAdmin);
    }

    function revokeAdmin(address _admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(GAMES_ADMIN_ROLE, _admin);
        _removeAdmin(_admin);
    }

    /**
     * @dev Remove an admin from the list of admins
     * @param account The address to remove
     */
    function _removeAdmin(address account) internal {
        if(account == address(0)) revert AddressZeroError();
        
        for(uint i = 0; i < s_admins.length; i++) {
            if(s_admins[i] == account) {
                s_admins[i] = s_admins[s_admins.length - 1];
                s_admins.pop();
                break;
            }
        }
    }


    function getAdmins() public view returns(address[] memory) {
        return s_admins;
    }

    function setGame(string memory _game) public onlyRole(GAMES_ADMIN_ROLE) gameNotExists(_game) { 
        s_games.push(_game);
        emit GameAdded(_game);
    }

    function setPlatform(string memory _platform) public onlyRole(GAMES_ADMIN_ROLE) platformNotExists(_platform) {
        s_platforms.push(_platform);
        emit PlatformAdded(_platform);
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
