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

    event onInitialWithdraw(address _user, uint256 _amount);
    event onWithdrawRewards(address _user, uint256 _rewards);
    event onWithdraw(address _user, uint256 _amount);
    event onEmergencyWithdraw();

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

    // TODO. Review parameters to use in the frontend
    function getData(address _user) external view returns (uint256 userTokensPerSec, uint256 amount, uint256 lastRewardsWithdraw, uint256 rewards) {
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
        require(balances[msg.sender].withdrawn < balances[msg.sender].amount, "Max");

        uint256 tokensPerSec = totalRewards / (stakeEndDate - stakeStartDate);
        uint256 userTokensPerSec = tokensPerSec * balances[msg.sender].amount / totalStakedAmount;
        uint256 from = balances[msg.sender].lastRewardsWithdraw == 0 ? stakeStartDate : balances[msg.sender].lastRewardsWithdraw;
        uint256 rewards = (block.timestamp - from) * userTokensPerSec;

        uint256 amount = balances[msg.sender].amount;
        totalStakedAmount -= amount;
        totalRewards -= rewards;

        uint256 tokens = calculateTokens(balances[msg.sender].investorType, amount) - balances[msg.sender].withdrawn;
        balances[msg.sender].withdrawn += tokens;

        IERC20(token).safeTransfer(msg.sender, tokens + rewards);

        emit onWithdraw(msg.sender, amount + rewards);
    }

    function calculateTokens(uint8 _investorType, uint256 _amount) internal view returns (uint256) {
        uint256 vestingDays = 0;
        if (_investorType == 1) vestingDays = 36 * 30 days;         // 1 - Angel
        else if (_investorType == 2) vestingDays = 30 * 30 days;    // 2 - Seed
        else if (_investorType == 3) vestingDays = 24 * 30 days;    // 3 - Strategic

        uint256 diffTime = block.timestamp - stakeStartDate;
        if (diffTime > vestingDays) diffTime = vestingDays;

        return diffTime * _amount / vestingDays; 
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw();
    }
}