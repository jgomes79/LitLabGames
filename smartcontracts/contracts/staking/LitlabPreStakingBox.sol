// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

contract LitlabPreStakingBox is Ownable {
    using SafeERC20 for IERC20;

    struct UserStake {
        uint256 amount;
        uint256 lastRewardsWithdraw;
        uint8 investorType; // 1 - Angel, 2 - Seed, 3 - Strategic
        bool claimedInitial;
        uint256 withdrawn;
    }

    address public token;
    uint256 public stakeStartDate;
    uint256 public stakeEndDate;
    uint256 public totalStakedAmount;
    uint256 public totalRewards;

    mapping(address => UserStake) private balances;

    event onFund(address _sender, uint256 _amount, uint256 _totalRewards);
    event onInitialWithdraw(address _user, uint256 _amount);
    event onWithdrawRewards(address _user, uint256 _rewards);
    event onWithdraw(address _user, uint256 _amount);

    constructor(address _token, uint256 _stakeStartDate, uint256 _stakeEndDate, uint256 _totalRewards) {
        token = _token;
        stakeStartDate = _stakeStartDate;
        stakeEndDate = _stakeEndDate;
        totalRewards = _totalRewards;
    }

    function stake(address[] memory _users, uint256[] memory _amounts, uint8[] memory _investorTypes) external onlyOwner {
        require(_users.length == _amounts.length, "BadLenghts");
        require(_investorTypes.length == _amounts.length, "BadLengths");
        
        uint total = 0;
        for (uint256 i=0; i<_users.length; i++) {
            address user = _users[i];
            uint256 amount = _amounts[i];
            uint8 investorType = _investorTypes[i];
            require(amount > 0, "BadAmount");

            balances[user] = UserStake({
                amount: amount,
                lastRewardsWithdraw: 0,
                investorType: investorType,
                claimedInitial: false,
                withdrawn: 0
            });

            total += amount;
        }

        totalStakedAmount = total;
    }

    // Añadir mas parametros para el front
    function getData(address _user) external returns (uint256 userTokensPerSec, uint256 amount, uint256 lastRewardsWithdraw, uint256 rewards) {
        userTokensPerSec = (totalRewards / (stakeEndDate - stakeStartDate)) * balances[_user].amount / totalStakedAmount;
        amount = balances[_user].amount;
        lastRewardsWithdraw = balances[_user].lastRewardsWithdraw;
        uint256 from = balances[_user].lastRewardsWithdraw == 0 ? stakeStartDate : balances[_user].lastRewardsWithdraw;
        rewards = (block.timestamp - from) * userTokensPerSec;
    }

    function withdrawInitial() external {
        require(block.timestamp >= stakeStartDate, "NotTGE");
        require(balances[msg.sender].amount > 0, "NoStaked");
        require(balances[msg.sender].claimedInitial == false, "Claimed");

        uint256 amount = balances[msg.sender].amount * 15 / 100;
        balances[msg.sender].amount -= amount;
        balances[msg.sender].claimedInitial = true;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit onInitialWithdraw(msg.sender, amount);
    }

    function withdrawRewards() external {
        require(balances[msg.sender].amount > 0, "NoStaked");
        require(balances[msg.sender].withdrawn == 0, "Withdrawn");
        require(block.timestamp >= stakeStartDate, "NotYet");

        uint256 tokensPerSec = totalRewards / (stakeEndDate - stakeStartDate);
        uint256 userTokensPerSec = tokensPerSec * balances[msg.sender].amount / totalStakedAmount;
        uint256 from = balances[msg.sender].lastRewardsWithdraw == 0 ? stakeStartDate : balances[msg.sender].lastRewardsWithdraw;
        uint256 rewards = (block.timestamp - from) * userTokensPerSec;

        balances[msg.sender].lastRewardsWithdraw += block.timestamp;
        IERC20(token).safeTransfer(msg.sender, rewards);

        emit onWithdrawRewards(msg.sender, rewards);
    }

    function withdraw() external {
        require(balances[msg.sender].amount > 0, "NoStaked");
        uint256 tokensPerSec = totalRewards / (stakeEndDate - stakeStartDate);
        uint256 userTokensPerSec = tokensPerSec * balances[msg.sender].amount / totalStakedAmount;
        uint256 from = balances[msg.sender].lastRewardsWithdraw == 0 ? stakeStartDate : balances[msg.sender].lastRewardsWithdraw;
        uint256 rewards = (block.timestamp - from) * userTokensPerSec;

        uint256 amount = balances[msg.sender].amount;
        totalStakedAmount -= amount;
        totalRewards -= rewards;
        balances[msg.sender].withdrawn += amount;

        IERC20(token).safeTransfer(msg.sender, amount + rewards);

        emit onWithdraw(msg.sender, amount + rewards);
    }

    function calculateTokens() internal returns (uint256) {
        
    }
}