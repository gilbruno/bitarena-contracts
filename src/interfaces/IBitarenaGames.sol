// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

interface IBitarenaGames {

    event GameAdded(string game);
    event PlatformAdded(string platform);

    function getGames() external view returns (string[] memory);
    function getPlatforms() external view returns (string[] memory);
    function grantNewAdmin(address _newAdmin) external;
    function setGame(string memory _game) external;
    function setPlatform(string memory _platform) external;
    function getGameByIndex(uint256 _gameIndex) external view returns (string memory);
    function getPlatformByIndex(uint256 _platformIndex) external view returns (string memory);

    /*
    * @dev an unexpected zero address was transmitted. (eg. `address(0)`)
    */
    error AddressZeroError();

    error GameAlreadyExists(string game);

    error PlatformAlreadyExists(string platform);

}