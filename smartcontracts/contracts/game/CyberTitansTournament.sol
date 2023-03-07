// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";
import "../token/ILitlabGamesToken.sol";
import "../metatx/LitlabContext.sol";

/// SmartContract for CyberTitans game modality. It's a centralized SmartContract.
/// Working mode:
/// - This SmartContract is intended to manage the user tournament join, retirement and distribute prizes
/// - Previously, users have approved this contract to spend LitlabGames ERC20 token in the litlabgames webpage
/// - Then, when users want to connect to the game, when matchmaking is done (8 playes), in the server, we call the functions:
///     - createTournament: To create a new tournament. Returns a tournament id
///     - joinTournament: To join a new user to a tournament
///     - retireTournament: To retire a user from a tournament
///     - finalizeTournament: When tournament has finished, send the winner wallets and distribute the prizes according the prizes matrix
contract CyberTitansTournament is LitlabContext, Ownable {
    using SafeERC20 for IERC20;

    struct TournamentStruct {
        uint256 playerBet;
        uint256 tournamentAssuredAmount;
        address token;
        uint24 numOfTokenPlayers;
        uint24 numOfCTTPlayers;
        uint64 startDate;
        uint64 endDate;
    }
    mapping(uint256 => TournamentStruct) private tournaments;
    uint256 tournamentCounter;

    uint16 public penalty;                          // If the user joint to a tournament and wants to retire before starting, there's a penalty he has to pay.

    address public wallet;
    address public manager;
    address public litlabToken;

    uint32[][8] public prizes;
    uint32[][8] public players;
    uint32[][12] public tops;
    uint8[8] public winners = [3, 4, 6, 8, 16, 32, 64, 128];

    uint16 public rake = 25;
    uint16 public fee = 25;
    bool private pause;

    event onTournamentCreated(uint256 _tournamentId);
    event onTournamentFinalized(uint256 _tournamentId);
    event onJoinedTournament(uint256 _id, address _player);
    event onRetiredTournament(uint256 _id, address _player);
    event onTournamentStarted(uint256 _id, uint24 _litPlayers, uint24 _cttPlayers);
    event onEmergencyWithdraw(uint256 _balance, address _token);

    constructor(address _forwarder, address _manager, address _wallet, address _litlabToken, uint8 _penalty) LitlabContext(_forwarder) {
        manager = _manager;
        wallet = _wallet;
        litlabToken = _litlabToken;
        penalty = _penalty;

        _buildArrays();
    }

    function _buildArrays() internal {
        prizes[0] = [5000000, 3000000, 2000000];
        prizes[1] = [4000000, 2700000, 1900000, 1400000];
        prizes[2] = [3200000, 2200000, 1650000, 1250000, 900000, 800000];
        prizes[3] = [2975000, 1875000, 1475000, 1125000, 850000, 700000, 550000, 450000];
        prizes[4] = [2575000, 1705000, 1100000, 850000, 625000, 500000, 400000, 317000, 241000];
        prizes[5] = [2000000, 1400000, 945000, 770000, 600000, 500000, 400000, 312500, 164063, 110000];
        prizes[6] = [1825000, 1325000, 842000, 700000, 562500, 460000, 360000, 265000, 130000, 73000, 45390];
        prizes[7] = [1780000, 1275000, 785000, 609200, 507500, 412000, 320000, 232500, 105000, 51000, 31712, 22000];

        players[0] = [1,8];
        players[1] = [9,16];
        players[2] = [17,32];
        players[3] = [33,64];
        players[4] = [65,128];
        players[5] = [129,256];
        players[6] = [257,512];
        players[7] = [512,1024];

        tops[0] = [1,1];
        tops[1] = [2,2];
        tops[2] = [3,3];
        tops[3] = [4,4];
        tops[4] = [5,5];
        tops[5] = [6,6];
        tops[6] = [7,7];
        tops[7] = [8,8];
        tops[8] = [9,16];
        tops[9] = [17,32];
        tops[10] = [33,64];
        tops[11] = [65,128];
    }

    function changeWallets(address _manager, address _wallet, address _litlabToken) external onlyOwner {
        manager = _manager;
        wallet = _wallet;
        litlabToken = _litlabToken;
    }

    function updateFees(uint16 _fee, uint16 _rake, uint16 _penalty) external onlyOwner {
        fee = _fee;
        rake = _rake;
        penalty = _penalty;
    }

    function changeArrays(uint32[][8] calldata _prizes, uint32[][8] calldata _players, uint32[][12] calldata _tops, uint8[8] calldata _winners) external onlyOwner {
        for (uint256 i=0; i<_prizes.length; i++) prizes[i] = _prizes[i];
        for (uint256 i=0; i<_players.length; i++) players[i] = _players[i];
        for (uint256 i=0; i<_tops.length; i++) tops[i] = _tops[i];
        for (uint256 i=0; i<_winners.length; i++) winners[i] = _winners[i];
    }

    function changePause() external onlyOwner {
        pause = !pause;
    }

    function createTournament(address _token, uint64 _startDate, uint64 _endDate, uint256 _playerBet, uint256 _tournamentAssuredAmount) external {
        require(_msgSender() == manager, "OnlyManager");
        require(pause == false, "Paused");
        require(_playerBet != 0, "BadAmount");
        require(_tournamentAssuredAmount != 0, "BadAmount");
        require(_token != address(0), "BadToken");

        uint tournamentId = ++tournamentCounter;
        TournamentStruct storage tournament = tournaments[tournamentId];
        tournament.token = _token;
        tournament.playerBet = _playerBet;
        tournament.tournamentAssuredAmount = _tournamentAssuredAmount;
        if (_startDate > 0) tournament.startDate = _startDate;
        if (_endDate > 0) tournament.endDate = _endDate;

        emit onTournamentCreated(tournamentId);
    }

    function joinTournament(uint256 _id) external {
        require(pause == false, "Paused");

        TournamentStruct storage tournament = tournaments[_id];
        if (tournament.startDate > 0) require(block.timestamp >= tournament.startDate, "NotStarted");
        if (tournament.endDate > 0) require(block.timestamp <= tournament.endDate, "Ended");
        
        tournament.numOfTokenPlayers++;
        IERC20(tournament.token).safeTransferFrom(_msgSender(), address(this), tournament.playerBet);

        emit onJoinedTournament(_id, _msgSender());
    }

    function getTournament(uint256 _id) external view returns(TournamentStruct memory) {
        return tournaments[_id];
    }

    function retireFromTournament(uint256 _id) external {
        require(pause == false, "Paused");
        
        // TODO. Pending of decision
        TournamentStruct memory tournament = tournaments[_id];
        tournament.numOfTokenPlayers--;
        IERC20(tournament.token).safeTransfer(_msgSender(), (tournament.playerBet - (tournament.playerBet * penalty / 1000)));
        IERC20(tournament.token).safeTransfer(wallet, (tournament.playerBet * penalty / 1000));

        emit onRetiredTournament(_id, _msgSender());
    }

    function startTournament(uint256 _id, uint24 _litPlayers, uint24 _cttPlayers) external {
        require(_msgSender() == manager, "OnlyManager");
        require(pause == false, "Paused");
        
        TournamentStruct storage tournament = tournaments[_id];
        require(_cttPlayers == tournament.numOfTokenPlayers, "BadLITTPlayers");
        tournament.numOfCTTPlayers = _cttPlayers;

        emit onTournamentStarted(_id, _litPlayers, _cttPlayers);
    }

    function finalizeTournament(uint256 _tournamentId, address[] calldata _winners) external {
        require(_msgSender() == manager, "OnlyManager");
        require(pause == false, "Paused");

        TournamentStruct memory tournament = tournaments[_tournamentId];
        // Get the num of players in the tournament
        uint24 numOfPlayers = tournament.numOfTokenPlayers + tournament.numOfCTTPlayers;
        // Get the prizes array
        uint256 index = _getPrizesColumn(numOfPlayers);
        require(winners[index] == _winners.length, "BadWinners");

        // Calculate if we got the minimum assurance token amount for the tournament. Otherwise, the game will add the tokens
        uint256 amountPlayed = tournament.playerBet * tournament.numOfTokenPlayers;
        if (amountPlayed < tournament.tournamentAssuredAmount) {
            IERC20(tournament.token).safeTransferFrom(wallet, address(this), tournament.tournamentAssuredAmount - amountPlayed);
            amountPlayed = tournament.tournamentAssuredAmount;
        }

        // Burn those tokens
        uint256 _rake = amountPlayed * rake / 1000;
        // Fee
        uint256 _fee = amountPlayed * fee / 1000;
        // Tournament pot
        uint256 pot = amountPlayed - (_rake + _fee);

        // For each player in the winners array
        uint8 i;
        do {
            // Get the player's prize
            uint256 prizePercentage = _getPrize(index, i+1);
            uint256 prize = (pot * prizePercentage) / (10 ** 7);
            if (prize != 0) IERC20(tournament.token).safeTransfer(_winners[i], prize);
            ++i;
        } while(i<_winners.length);

        // Burn the rake and get the fee
        if (tournament.token == litlabToken) {
            // If we are using litlabtoken, burn the rake
            ILitlabGamesToken(tournament.token).burn(_rake);
            IERC20(tournament.token).safeTransfer(wallet, _fee);
        } else {
            // If we are using other token, transfer the rake instead of burning
            IERC20(tournament.token).safeTransfer(wallet, (_rake + _fee));
        }

        emit onTournamentFinalized(_tournamentId);
    }

    function _getPrizesColumn(uint24 _numOfPlayers) internal view returns(uint16) {
        uint16 index;
        do {
            if (_numOfPlayers >= players[index][0] && _numOfPlayers <= players[index][1]) break;
            ++index;
        } while (index < 8);
    
        assert(index < 8);
        return index;
    }

    function _getPrize(uint256 _index, uint256 _position) internal view returns(uint32) {
        uint8 index;
        do {
            if (_position >= tops[index][0] && _position <= tops[index][1]) break;
            ++index;
        } while(index < 12);

        assert(index < 12);
        return prizes[_index][index];
    }

    function emergencyWithdraw(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(owner, balance);

        emit onEmergencyWithdraw(balance, _token);
    }
}