// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";
import "../token/ILitlabGamesToken.sol";

import "@ganache/console.log/console.sol";

contract CyberTitansGame is Ownable {
    using SafeERC20 for ILitlabGamesToken;

    struct GameStruct {
        uint256 totalBet;
        address token;
        uint256 startDate;
    }
    mapping(uint256 => GameStruct) private games;
    uint256 gameCounter;

    address public wallet;
    address public manager;

    uint16[] public winners = [475, 285, 190];
    uint16 public rake = 25;
    uint16 public fee = 25;
    uint16 public waitMinutes = 15;
    bool private pause;

    event onGameCreated(uint256 _gameId);
    event onGameFinalized(uint256 _gameId, address[] _winners);
    event onEmergencyWithdraw(uint256 _balance, address _token);

    constructor(address _manager, address _wallet) {
        manager = _manager;
        wallet = _wallet;
    }

    function changeWallets(address _manager, address _wallet) external onlyOwner {
        manager = _manager;
        wallet = _wallet;
    }

    function changeWinners(uint16[] memory _winners) external onlyOwner {
        require(_winners.length > 0, "BadLength");

        winners = new uint16[](_winners.length);
        for (uint256 i=0; i< _winners.length; i++) winners[i] = _winners[i];
    }

    function updateFees(uint16 _fee, uint16 _rake) external onlyOwner {
        fee = _fee;
        rake = _rake;
    }

    function updateWaitMinutes(uint16 _waitMinutes) external onlyOwner {
        waitMinutes = _waitMinutes;
    }

    function changePause() external onlyOwner {
        pause = !pause;
    }

    function checkWallets(address[] memory _players, uint256 _amount, address _token) external view returns (uint256[] memory) {
        uint256[] memory info = new uint256[](_players.length); 
        for (uint256 i=0; i<_players.length; i++) {
            uint256 balance = ILitlabGamesToken(_token).balanceOf(_players[i]);
            uint256 allowance = ILitlabGamesToken(_token).allowance(_players[i], address(this));

            if (allowance >= _amount && balance >= _amount) info[i] = 0;
            else if (allowance < _amount) info[i] = 1;
            else if (balance < _amount) info[i] = 2;
        }

        return info;
    }

    function createGame(address[] memory _players, address _token, uint256 _amount) external {
        //require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");
        require(_players.length > 0, "BadArray");
        require(_amount > 0, "BadAmount");
        require(_token != address(0), "BadToken");

        uint gameId = ++gameCounter;

        games[gameId] = GameStruct({
            totalBet: _amount * _players.length,
            token: _token,
            startDate: block.timestamp
        });

        for (uint256 i=0; i<_players.length; i++) ILitlabGamesToken(_token).safeTransferFrom(_players[i], address(this), _amount);

        emit onGameCreated(gameId);
    }

    function finalizeGame(uint256 _gameId, address[] calldata _winners) external {
        //require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");

        GameStruct memory game = games[_gameId];
        require(block.timestamp >= game.startDate + (waitMinutes * 1 minutes), "WaitXMinutes");

        for (uint256 i=0; i<_winners.length; i++) ILitlabGamesToken(game.token).safeTransfer(_winners[i], game.totalBet * winners[i] / 1000);

        ILitlabGamesToken(game.token).burn(game.totalBet * fee / 1000);
        ILitlabGamesToken(game.token).safeTransfer(wallet, game.totalBet * rake / 1000);

        emit onGameFinalized(_gameId, _winners);
    }

    function emergencyWithdraw(address _token) external onlyOwner {
        uint256 balance = ILitlabGamesToken(_token).balanceOf(address(this));
        ILitlabGamesToken(_token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw(balance, _token);
    }
}