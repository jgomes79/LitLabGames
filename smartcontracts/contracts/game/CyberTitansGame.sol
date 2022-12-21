// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";
import "../token/ILitlabGamesToken.sol";

import "@ganache/console.log/console.sol";

contract CyberTitansGame is Ownable {
    using SafeERC20 for ILitlabGamesToken;

    struct GameStruct {
        address[] players;
        uint256 totalBet;
        address token;
        uint256 startDate;
    }
    mapping(uint256 => GameStruct) private games;
    uint256 gameCounter;

    address public wallet;
    address public poolWallet;
    address public manager;
    address public signer;

    uint16[] public bets = [1, 10, 100, 500, 1000, 5000];
    uint16[] public winners = [475, 285, 190];
    uint16 public fee = 25;
    uint16 public waitMinutes = 15;
    bool private pause;

    event onGameCreated(uint256 _gameId);
    event onGameFinalized(uint256 _gameId, address _winner1, address _winner2, address _winner3);

    constructor(address _manager, address _wallet, address _poolWallet) {
        manager = _manager;
        wallet = _wallet;
        poolWallet = _poolWallet;
    }

    function changeWallets(address _manager, address _wallet, address _poolWallet) external onlyOwner {
        manager = _manager;
        wallet = _wallet;
        poolWallet = _poolWallet;
    }

    function updateBets(uint16[] memory _bets) external onlyOwner {
        delete bets;
        bets = _bets;
    }

    function updateFee(uint16 _fee) external onlyOwner {
        fee = _fee;
    }

    function updateWaitMinutes(uint16 _waitMinutes) external onlyOwner {
        waitMinutes = _waitMinutes;
    }

    function changePause() external onlyOwner {
        pause = !pause;
    }

    function createGame(address[] memory _players, bool[] memory _ctt, address _token, uint256 _betIndex) external {
        require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");
        require(_betIndex >= 0 && _betIndex <= bets.length, "BadIndex");
        require(_players.length == _ctt.length, "BadArrays");

        console.log("Todos los checks pasan");
        console.log("bets[index]: %d", bets[_betIndex]);
        console.log("bets[index] multiplied: %d", uint256(bets[_betIndex]) * 10 ** 18);

        uint gameId = ++gameCounter;
        uint256 bet = uint256(bets[_betIndex]) * 10 ** 18;

        console.log("totalBet: %d", bet * _players.length);
            
        games[gameId] = GameStruct({
            players: _players,
            totalBet: bet * _players.length,
            token: _token,
            startDate: block.timestamp
        });

        for (uint256 i=0; i<_players.length; i++) {
            if (_ctt[i] == false) ILitlabGamesToken(_token).safeTransferFrom(_players[i], address(this), bet);
            else ILitlabGamesToken(_token).safeTransferFrom(poolWallet, address(this), bet);
        }

        emit onGameCreated(gameId);
    }

    function finalizeGame(uint256 _gameId, address _winner1, address _winner2, address _winner3) external {
        require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");
        // TODO. Check that winners where in the initial players

        GameStruct memory game = games[_gameId];
        require(block.timestamp >= game.startDate + (waitMinutes * 1 minutes), "WaitXMinutes");

        ILitlabGamesToken(game.token).safeTransfer(_winner1, game.totalBet * winners[0] / 1000);
        ILitlabGamesToken(game.token).safeTransfer(_winner2, game.totalBet * winners[1] / 1000);
        ILitlabGamesToken(game.token).safeTransfer(_winner3, game.totalBet * winners[2] / 1000);

        ILitlabGamesToken(game.token).burn(game.totalBet * fee / 1000);
        ILitlabGamesToken(game.token).safeTransfer(wallet, game.totalBet * fee / 1000);

        emit onGameFinalized(_gameId, _winner1, _winner2, _winner3);
    }
}