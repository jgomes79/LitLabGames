// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";
import "../token/ILitlabGamesToken.sol";

// DON'T AUDIT YET. THIS SMARTCONTRACT IS NOT FINISHED YET...
contract CyberTitansTournament is Ownable {
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
    address public manager;
    address public signer;

    uint16[] public bets = [1, 10, 100, 500, 1000, 5000];
    uint16[] public winners = [475, 285, 190];
    uint16 public fee = 25;
    bool private pause;

    event onGameCreated(uint256 _id, GameStruct _game);

    constructor(address _manager, address _signer, address _wallet) {
        manager = _manager;
        signer = _signer;
        wallet = _wallet;
    }

    function changeWallets(address _manager, address _signer, address _wallet) external onlyOwner {
        manager = _manager;
        signer = _signer;
        wallet = _wallet;
    }

    function updateBets(uint16[] memory _bets) external onlyOwner {
        delete bets;
        bets = _bets;
    }

    function updateFee(uint16 _fee) external onlyOwner {
        fee = _fee;
    }

    function changePause() external onlyOwner {
        pause = !pause;
    }

    function startGame(address[] memory _players, address _token, uint256 _betIndex) external {
        require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");
        require(_betIndex >= 0 && _betIndex <= bets.length, "BadIndex");

        uint gameId = ++gameCounter;
        uint256 bet = bets[_betIndex] * 10 ** 18;
            
        games[gameId] = GameStruct({
            players: _players,
            totalBet: bet * _players.length,
            token: _token,
            startDate: block.timestamp
        });

        for (uint256 i=0; i<=_players.length; i++) {
            ILitlabGamesToken(_token).safeTransferFrom(_players[i], address(this), bet);
        }

        emit onGameCreated(gameId, games[gameId]);
    }

    function finalizeGame(bytes calldata _message, bytes calldata _messageLen, bytes calldata _signature) external {
        require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");

        (uint256 gameId, address winner1, address winner2, address winner3) = abi.decode(_message,(uint256, address, address, address));
        address _signer = _decodeSignature(_message, _messageLen, _signature);
        require(_signer == signer, "BadSigner");

        GameStruct memory game = games[gameId];
        require(block.timestamp >= game.startDate + 10 minutes, "Wait10Minutes");

        ILitlabGamesToken(game.token).safeTransfer(winner1, game.totalBet * winners[0] / 1000);
        ILitlabGamesToken(game.token).safeTransfer(winner2, game.totalBet * winners[1] / 1000);
        ILitlabGamesToken(game.token).safeTransfer(winner3, game.totalBet * winners[2] / 1000);

        ILitlabGamesToken(game.token).burn(game.totalBet * fee / 1000);
        ILitlabGamesToken(game.token).safeTransfer(wallet, game.totalBet * fee / 1000);
    }

    function _decodeSignature(bytes memory _message, bytes memory _messageLength, bytes memory _signature) internal pure returns (address) {
        if (_signature.length != 65) return (address(0));

        bytes32 messageHash = keccak256(abi.encodePacked(hex"19457468657265756d205369676e6564204d6573736167653a0a", _messageLength, _message));
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);
        if (v != 27 && v != 28) return address(0);
        
        return ecrecover(messageHash, v, r, s);
    }
}