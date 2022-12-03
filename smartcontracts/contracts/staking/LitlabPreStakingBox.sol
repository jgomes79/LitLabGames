// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

contract LitlabPreStakingBox is Ownable {
    using SafeERC20 for IERC20;

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

    event onGameCreated(uint256 _id);

    constructor(address _manager, address _signer, address _wallet) {
        manager = _manager;
        signer = _signer;
        wallet = _wallet;
    }
}