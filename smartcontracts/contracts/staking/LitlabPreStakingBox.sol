// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

contract LitlabPreStakingBox is Ownable {
    using SafeERC20 for IERC20;

    enum InvestorType {
        ANGEL,
        SEED,
        STRATEGIC
    }

    struct UserStake {
        uint256 amount;
        uint256 lastRewardsWithdraw;
        InvestorType investorType;
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

    // Stake function. Only the owner sets up the initial stake configuration adding users, amounts and the investor type (different vesting)
    function stake(address[] memory _users, uint256[] memory _amounts, uint8[] memory _investorTypes) external onlyOwner {
        require(_users.length == _amounts.length, "BadLenghts");
        require(_investorTypes.length == _amounts.length, "BadLengths");
        
        uint total = 0;
        for (uint256 i=0; i<_users.length; i++) {
            address user = _users[i];
            uint256 amount = _amounts[i];
            InvestorType investorType = InvestorType(_investorTypes[i]);
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

    // At TGE users can withdraw the 15% of their investment. Only one time
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

    // Users can withdraw rewards whenever they want but if they withdraw
    function withdrawRewards() external {
        require(balances[msg.sender].amount > 0, "NoStaked");
        require(balances[msg.sender].withdrawn == 0, "Withdrawn");
        require(block.timestamp >= stakeStartDate, "NotYet");
        require(block.timestamp <= stakeEndDate, "StakingFinished");

        (, , , ,  uint256 pendingRewards, uint256 to) = _getData(msg.sender);
        require(pendingRewards > 0, "NoRewardsToClaim");

        balances[msg.sender].lastRewardsWithdraw = to;
        IERC20(token).safeTransfer(msg.sender, pendingRewards);

        emit onWithdrawRewards(msg.sender, pendingRewards);
    }

    // Users withdraws all the balance they can
    function withdraw() external {
        require(balances[msg.sender].amount > 0, "NoStaked");
        require(balances[msg.sender].withdrawn < balances[msg.sender].amount, "Max");

        uint256 amount = 0;
        uint256 rewards = 0;
        if (balances[msg.sender].withdrawn == 0) {
            (uint256 userAmount, uint256 withdrawn, , ,  uint256 pendingRewards, uint256 to) = _getData(msg.sender);
            totalStakedAmount -= userAmount;
            totalRewards -= pendingRewards;

            uint256 tokens = _calculateTokens(balances[msg.sender].investorType, userAmount) - withdrawn;
            balances[msg.sender].withdrawn += tokens;
            balances[msg.sender].lastRewardsWithdraw = to;

            IERC20(token).safeTransfer(msg.sender, tokens + pendingRewards);
        } else {
            amount = balances[msg.sender].amount;
            uint256 tokens = _calculateTokens(balances[msg.sender].investorType, amount) - balances[msg.sender].withdrawn;
            balances[msg.sender].withdrawn += tokens;

            IERC20(token).safeTransfer(msg.sender, tokens);
        }

        emit onWithdraw(msg.sender, amount + rewards);
    }

    function getData(address _user) external view returns (uint256 amount, uint256 withdrawn, uint256 userTokensPerSec,  uint256 lastRewardsWithdraw,  uint256 pendingRewards, uint256 to) {
        return _getData(_user);
    }

    function getTokensInContract() external view returns (uint256 tokens) {
        tokens = IERC20(token).balanceOf(address(this));
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw();
    }

    function _calculateTokens(InvestorType _investorType, uint256 _amount) internal view returns (uint256) {
        uint256 vestingDays = 0;
        if (_investorType == InvestorType.ANGEL) vestingDays = 36 * 30 days;
        else if (_investorType == InvestorType.SEED) vestingDays = 30 * 30 days;
        else if (_investorType == InvestorType.STRATEGIC) vestingDays = 24 * 30 days;

        uint256 diffTime = block.timestamp - stakeStartDate;
        if (diffTime > vestingDays) diffTime = vestingDays;

        return diffTime * _amount / vestingDays; 
    }

    function _getData(address _user) internal view returns (uint256 userAmount, uint256 withdrawn, uint256 userTokensPerSec,  uint256 lastRewardsWithdraw,  uint256 pendingRewards, uint256 to) {
        userAmount = balances[_user].amount;
        withdrawn = balances[_user].withdrawn;
        userTokensPerSec = (totalRewards / (stakeEndDate - stakeStartDate)) * balances[_user].amount / totalStakedAmount;
        lastRewardsWithdraw = balances[_user].lastRewardsWithdraw;
        uint256 from = balances[_user].lastRewardsWithdraw == 0 ? stakeStartDate : balances[_user].lastRewardsWithdraw;
        to = block.timestamp > stakeEndDate ? stakeEndDate : block.timestamp;
        pendingRewards = withdrawn == 0 ? (to - from) * userTokensPerSec : 0;
    }
}