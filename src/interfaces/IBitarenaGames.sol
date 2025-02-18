// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

interface IBitarenaGames {

    event GameAdded(string game);
    event PlatformAdded(string platform);
    event ModeAdded(string mode);
    event GameSupportUpdated(
        string game,
        string[] platforms,
        string[] modes
    );

    function getGames() external view returns (string[] memory);
    function getPlatforms() external view returns (string[] memory);
    function grantNewAdmin(address _newAdmin) external;
    function setGame(string memory _game) external;
    function setPlatform(string memory _platform) external;
    function getGameByIndex(uint256 _gameIndex) external view returns (string memory);
    function getPlatformByIndex(uint256 _platformIndex) external view returns (string memory);
    function setMode(uint16 _nbTeams, uint16 _nbPlayerPerTeam) external;
    function getModes() external view returns (string[] memory);
    function getModeByIndex(uint256 _modeIndex) external view returns (string memory);
    function getMode(uint16 _nbTeams, uint16 _nbPlayerPerTeam) external pure returns (string memory);

    function setGameSupport(
        string memory _game,
        string[] memory _platforms,
        string[] memory _modes
    ) external;

    function getGameSupport(string memory _game) external view returns (
        string[] memory platforms,
        string[] memory modes
    );

    error AddressZeroError();
    error GameAlreadyExists(string game);
    error PlatformAlreadyExists(string platform);
    error ModeAlreadyExists(string mode);
    error GameNotFound(string game);
    error PlatformNotFound(string platform);
    error ModeNotFound(string mode);

}