// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";
import "../token/ILitlabGamesToken.sol";

/// SmartContract for CyberTitans game modality. It's a centralized SmartContract.
/// Working mode:
/// - This SmartContract is intended to manage the user tournament join, retirement and distribute prizes
/// - Previously, users have approved this contract to spend LitlabGames ERC20 token in the litlabgames webpage
/// - Then, when users want to connect to the game, when matchmaking is done (8 playes), in the server, we call the functions:
///     - createTournament: To create a new tournament. Returns a tournament id
///     - joinTournament: To join a new user to a tournament
///     - retireTournament: To retire a user from a tournament
///     - finalizeTournament: When tournament has finished, send the winner wallets and distribute the prizes according the prizes matrix
contract CyberTitansTournament is Ownable {
    using SafeERC20 for IERC20;

    struct TournamentStruct {
        uint256 bet;
        address token;
        uint24 numOfPlayers;
        uint64 startDate;
        uint64 endDate;
    }
    mapping(uint256 => TournamentStruct) private tournaments;
    uint256 tournamentCounter;

    uint256 public maxBetAmount;                    // Security. Don't let create a game with a bet greater than this variable
    uint16 public penalty;                          // If the user joint to a tournament and wants to retire before starting, there's a penalty he has to pay.

    address public wallet;
    address public manager;
    address public litlabToken;

    uint16[] public bets = [1, 10, 100, 500, 1000, 5000];
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
    event onEmergencyWithdraw(uint256 _balance, address _token);

    constructor(address _manager, address _wallet, address _litlabToken, uint256 _maxBetAmount, uint8 _penalty) {
        manager = _manager;
        wallet = _wallet;
        litlabToken = _litlabToken;
        maxBetAmount = _maxBetAmount;
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

    function createTournament(address _token, uint64 _startDate, uint256 _amount) external {
        require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");
        require(_amount != 0, "BadAmount");
        require(_amount <= maxBetAmount, "MaxAmount");
        require(_token != address(0), "BadToken");

        uint tournamentId = ++tournamentCounter;
        TournamentStruct storage tournament = tournaments[tournamentId];
        tournament.token = _token;
        tournament.bet = _amount;
        tournament.startDate = _startDate;

        emit onTournamentCreated(tournamentId);
    }

    function joinTournament(uint256 _id, address _wallet, bool _isCTT) external {
        require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");

        TournamentStruct storage tournament = tournaments[_id];
        if (tournament.startDate > 0) require(block.timestamp >= tournament.startDate, "NotStarted");
        if (tournament.endDate > 0) require(block.timestamp <= tournament.endDate, "Ended");
        
        tournament.numOfPlayers++;
        if (_isCTT) IERC20(tournament.token).safeTransferFrom(wallet, address(this), tournament.bet);
        else IERC20(tournament.token).safeTransferFrom(_wallet, address(this), tournament.bet);

        emit onJoinedTournament(_id, msg.sender);
    }

    function getTournament(uint256 _id) external view returns(TournamentStruct memory) {
        return tournaments[_id];
    }

    function retireFromTournament(uint256 _id, address _wallet) external {
        require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");
        
        // TODO. Pending of decision
        TournamentStruct memory tournament = tournaments[_id];
        IERC20(tournament.token).safeTransfer(_wallet, (tournament.bet - (tournament.bet * penalty / 1000)));

        emit onRetiredTournament(_id, msg.sender);
    }

    function finalizeTournament(uint256 _tournamentId, address[] calldata _winners) external {
        require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");

        TournamentStruct memory tournament = tournaments[_tournamentId];
        uint256 index = _getPrizesColumn(tournament.numOfPlayers);
        require(winners[index] == _winners.length, "BadWinners");

        uint256 totalBet = tournament.bet * tournament.numOfPlayers;
        uint256 _rake = totalBet * rake / 1000;
        uint256 _fee = totalBet * fee / 1000;

        uint256 pot = totalBet - (_rake + _fee);

        uint8 i;
        do {
            uint256 prizePercentage = _getPrize(index, i+1);
            uint256 prize = (pot * prizePercentage) / (10 ** 7);
            if (prize != 0) IERC20(tournament.token).safeTransfer(_winners[i], prize);
            ++i;
        } while(i<_winners.length);

        if (tournament.token == litlabToken) {
            ILitlabGamesToken(tournament.token).burn(_rake);
            IERC20(tournament.token).safeTransfer(wallet, _fee);
        } else {
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
        IERC20(_token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw(balance, _token);
    }
}