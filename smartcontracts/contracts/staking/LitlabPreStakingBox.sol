// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

/// @title PRESTAKING BOX
/// @notice Staking contract for investors. At deployement we send all the tokens for each investor to this contract with a plus amount of rewards
contract LitlabPreStakingBox is Ownable {
    using SafeERC20 for IERC20;

    enum InvestorType {
        ANGEL,
        SEED,
        STRATEGIC
    }

    struct UserStake {
        uint256 amount;
        uint256 withdrawn;
        uint256 lastRewardsWithdraw;
        InvestorType investorType;
        bool claimedInitial;
        bool withdrawnFirst;
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

    /// @notice Constructor
    /// @param _token Address of the litlab token
    /// @param _stakeStartDate Start date of staking
    /// @param _stakeEndDate End date of staking
    /// @param _totalRewards Rewards for the staking   
    constructor(address _token, uint256 _stakeStartDate, uint256 _stakeEndDate, uint256 _totalRewards) {
        token = _token;
        stakeStartDate = _stakeStartDate;
        stakeEndDate = _stakeEndDate;
        totalRewards = _totalRewards;
    }

    /// @notice Stake function. Call at the deployment by the owner only one time to fill the investors amounts
    /// @param _users Array with all the address of the investors
    /// @param _amounts Array with the investment amounts
    /// @param _investorTypes Array with the investor types (to calculate the vesting period)
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
                withdrawn: 0,
                lastRewardsWithdraw: 0,
                investorType: investorType,
                claimedInitial: false,
                withdrawnFirst: false
            });

            total += amount;
        }

        totalStakedAmount = total;
    }

    /// @notice At TGE users can withdraw the 15% of their investment. Only one time
    function withdrawInitial() external {
        require(block.timestamp >= stakeStartDate, "NotTGE");
        require(balances[msg.sender].amount > 0, "NoStaked");
        require(balances[msg.sender].claimedInitial == false, "Claimed");

        uint256 amount = balances[msg.sender].amount * 15 / 100;
        balances[msg.sender].withdrawn += amount;
        balances[msg.sender].claimedInitial = true;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit onInitialWithdraw(msg.sender, amount);
    }

    /// @notice Users can withdraw rewards whenever they want with no penalty only if they don't withdraw previously
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

    /// @notice Users withdraws all the balance according their vesting, but they couldn't withdraw rewards any more with the witdrawRewards function
    function withdraw() external {
        require(balances[msg.sender].amount > 0, "NoStaked");
        require(balances[msg.sender].withdrawn < balances[msg.sender].amount, "Max");

        uint256 amount = 0;
        uint256 rewards = 0;
        if (balances[msg.sender].withdrawnFirst == false) {
            // It's the first time we use a regular withdraw. Calculate the pending rewards and send to the user.
            (uint256 userAmount, uint256 withdrawn, , ,  uint256 pendingRewards, uint256 to) = _getData(msg.sender);
            // This is the last time this user can get rewards, and the rest of the rewards are splitted for the other users.
            totalStakedAmount -= userAmount;
            totalRewards -= pendingRewards;

            uint256 tokens = _calculateTokens(balances[msg.sender].investorType, userAmount) - withdrawn;
            balances[msg.sender].withdrawn += tokens;
            balances[msg.sender].lastRewardsWithdraw = to;
            balances[msg.sender].withdrawnFirst = true;

            IERC20(token).safeTransfer(msg.sender, tokens + pendingRewards);
        } else {
            amount = balances[msg.sender].amount;
            uint256 tokens = _calculateTokens(balances[msg.sender].investorType, amount) - balances[msg.sender].withdrawn;
            balances[msg.sender].withdrawn += tokens;

            IERC20(token).safeTransfer(msg.sender, tokens);
        }

        emit onWithdraw(msg.sender, amount + rewards);
    }

    /// @notice Get the data for each user (to show in the frontend dapp)
    function getData(address _user) external view returns (uint256 amount, uint256 withdrawn, uint256 userTokensPerSec,  uint256 lastRewardsWithdraw,  uint256 pendingRewards, uint256 to) {
        return _getData(_user);
    }

    /// @notice Quick way to know how many tokens are pending in the contract
    function getTokensInContract() external view returns (uint256 tokens) {
        tokens = IERC20(token).balanceOf(address(this));
    }

    /// @notice If there's any problem, contract owner can withdraw all funds (this is not a public and open stake, it's only for authorized investors)
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw();
    }

    /// @notice Calculate the token vesting according the investor type
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