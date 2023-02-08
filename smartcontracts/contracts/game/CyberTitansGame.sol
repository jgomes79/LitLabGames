// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";
import "../token/ILitlabGamesToken.sol";

contract CyberTitansGame is Ownable {
    using SafeERC20 for IERC20;

    struct GameStruct {
        address[] players;
        uint256 totalBet;
        address token;
        uint256 startDate;
        uint256 endDate;
    }
    mapping(uint256 => GameStruct) private games;
    uint256 gameCounter;

    address public wallet;
    address public manager;
    address public litlabToken;

    uint16[] public winners = [475, 285, 190];
    uint16 public rake = 25;
    uint16 public fee = 25;
    uint16 public waitMinutes = 15;
    bool private pause;

    event onGameCreated(uint256 _gameId);
    event onGameFinalized(uint256 _gameId, address[] _winners);
    event onEmergencyWithdraw(uint256 _balance, address _token);

    constructor(address _manager, address _wallet, address _litlabToken) {
        manager = _manager;
        wallet = _wallet;
        litlabToken = _litlabToken;
    }

    function changeWallets(address _manager, address _wallet, address _litlabToken) external onlyOwner {
        manager = _manager;
        wallet = _wallet;
        litlabToken = _litlabToken;
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
            uint256 balance = IERC20(_token).balanceOf(_players[i]);
            uint256 allowance = IERC20(_token).allowance(_players[i], address(this));

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
            players: _players,
            totalBet: _amount * _players.length,
            token: _token,
            startDate: block.timestamp,
            endDate: 0
        });

        for (uint256 i=0; i<_players.length; i++) IERC20(_token).safeTransferFrom(_players[i], address(this), _amount);

        emit onGameCreated(gameId);
    }

    function finalizeGame(uint256 _gameId, address[] calldata _winners) external {
        //require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");
        require(_checkPlayers(_gameId, _winners) == true, "BadPlayers");

        GameStruct storage game = games[_gameId];
        require(block.timestamp >= game.startDate + (waitMinutes * 1 minutes), "WaitXMinutes");
        require(game.endDate == 0, "AlreadyEnd");
        game.endDate = block.timestamp;

        for (uint256 i=0; i<_winners.length; i++) IERC20(game.token).safeTransfer(_winners[i], game.totalBet * winners[i] / 1000);

        if (game.token == litlabToken) {
            ILitlabGamesToken(game.token).burn(game.totalBet * fee / 1000);
            IERC20(game.token).safeTransfer(wallet, game.totalBet * rake / 1000);
        } else {
            IERC20(game.token).safeTransfer(wallet, ((game.totalBet * rake) + (game.totalBet * fee)) / 1000);
        }

        emit onGameFinalized(_gameId, _winners);
    }

    function emergencyWithdraw(address _token) external onlyOwner {
        uint256 balance = ILitlabGamesToken(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw(balance, _token);
    }

    function _checkPlayers(uint256 _gameId, address[] calldata _players) internal view returns(bool) {
        address[] memory gamePlayers = games[_gameId].players;

        uint256 playersOk = 0;
        for (uint256 i=0; i<_players.length; i++) {
            for (uint256 j=0; j<gamePlayers.length; j++) {
                if (_players[i] == gamePlayers[j]) {
                    playersOk++;
                    break;
                }
            }
            if (playersOk == _players.length) return true;
        }

        return false;
    }
}