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

    string[] private s_modes;

    struct GameSupport {
        string[] platforms;
        string[] modes;
    }

    mapping(string => GameSupport) private s_gameSupport;

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

    modifier modeNotExists(string memory _mode) {
        for(uint i = 0; i < s_modes.length; i++) {
            if(keccak256(bytes(s_modes[i])) == keccak256(bytes(_mode))) {
                revert ModeAlreadyExists(_mode);
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

        /**
     * @notice Ajoute ou met à jour les plateformes et modes supportés pour un jeu
     * @param _game Le nom du jeu
     * @param _platforms Les plateformes supportées
     * @param _modes Les modes de jeu supportés
     */
    function setGameSupport(
        string memory _game,
        string[] memory _platforms,
        string[] memory _modes
    ) public onlyRole(GAMES_ADMIN_ROLE) {
        // Vérifier que le jeu existe
        bool gameExists = false;
        for(uint i = 0; i < s_games.length; i++) {
            if(keccak256(bytes(s_games[i])) == keccak256(bytes(_game))) {
                gameExists = true;
                break;
            }
        }
        if(!gameExists) revert GameNotFound(_game);

        // Vérifier que toutes les plateformes existent
        for(uint i = 0; i < _platforms.length; i++) {
            bool platformExists = false;
            for(uint j = 0; j < s_platforms.length; j++) {
                if(keccak256(bytes(s_platforms[j])) == keccak256(bytes(_platforms[i]))) {
                    platformExists = true;
                    break;
                }
            }
            if(!platformExists) revert PlatformNotFound(_platforms[i]);
        }

        // Vérifier que tous les modes existent
        for(uint i = 0; i < _modes.length; i++) {
            bool modeExists = false;
            for(uint j = 0; j < s_modes.length; j++) {
                if(keccak256(bytes(s_modes[j])) == keccak256(bytes(_modes[i]))) {
                    modeExists = true;
                    break;
                }
            }
            if(!modeExists) revert ModeNotFound(_modes[i]);
        }

        // Mettre à jour le support
        s_gameSupport[_game] = GameSupport({
            platforms: _platforms,
            modes: _modes
        });

        emit GameSupportUpdated(_game, _platforms, _modes);
    }

    function getMode(uint16 _nbTeams, uint16 _nbPlayerPerTeam) public pure returns (string memory) {
        // Calculer d'abord la longueur nécessaire
        uint256 numLength = bytes(_toString(_nbPlayerPerTeam)).length;
        uint256 totalLength = (numLength * _nbTeams) + (_nbTeams - 1); // longueur totale = (taille du nombre * nb équipes) + (nb tirets)
        
        bytes memory result = new bytes(totalLength);
        uint256 pos = 0;
        
        for (uint16 i = 0; i < _nbTeams; i++) {
            bytes memory num = bytes(_toString(_nbPlayerPerTeam));
            for (uint256 j = 0; j < num.length; j++) {
                result[pos++] = num[j];
            }
            
            if (i < _nbTeams - 1) {
                result[pos++] = "-";
            }
        }
        return string(result);
    }

    function _toString(uint16 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        uint16 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint16(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }


    /**
     * @notice Récupère les plateformes et modes supportés pour un jeu
     * @param _game Le nom du jeu
     * @return platforms Les plateformes supportées
     * @return modes Les modes de jeu supportés
     */
    function getGameSupport(string memory _game) public view returns (
        string[] memory platforms,
        string[] memory modes
    ) {
        GameSupport memory support = s_gameSupport[_game];
        return (support.platforms, support.modes);
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

    function setMode(uint16 _nbTeams, uint16 _nbPlayerPerTeam) public onlyRole(GAMES_ADMIN_ROLE) modeNotExists(getMode(_nbTeams, _nbPlayerPerTeam)) {
        s_modes.push(getMode(_nbTeams, _nbPlayerPerTeam));
        emit ModeAdded(getMode(_nbTeams, _nbPlayerPerTeam));
    }

    function getModes() public view returns (string[] memory) {
        return s_modes;
    }

    function getModeByIndex(uint256 _modeIndex) public view returns (string memory) {
        return s_modes[_modeIndex];
    }

}
