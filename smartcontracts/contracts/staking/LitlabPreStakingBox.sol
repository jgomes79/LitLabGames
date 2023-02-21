// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

/// PRESTAKING BOX
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
        uint256 lastRewardsWithdrawn;
        uint256 lastUserWithdrawn;
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
                lastRewardsWithdrawn: 0,
                lastUserWithdrawn: 0,
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
        require(balances[msg.sender].amount != 0, "NoStaked");
        require(balances[msg.sender].claimedInitial == false, "Claimed");

        uint256 amount = balances[msg.sender].amount * 15 / 100;
        balances[msg.sender].withdrawn += amount;
        balances[msg.sender].claimedInitial = true;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit onInitialWithdraw(msg.sender, amount);
    }

    /// @notice Users can withdraw rewards whenever they want with no penalty only if they don't withdraw previously
    function withdrawRewards() external {
        require(balances[msg.sender].amount != 0, "NoStaked");
        require(balances[msg.sender].withdrawnFirst == false, "Withdrawn");
        require(block.timestamp >= stakeStartDate, "NotYet");
        require(block.timestamp <= stakeEndDate, "StakingFinished");

        (, , , , , , uint256 pendingRewards, uint256 to) = _getData(msg.sender);
        require(pendingRewards > 0, "NoRewardsToClaim");

        balances[msg.sender].lastRewardsWithdrawn = to;
        IERC20(token).safeTransfer(msg.sender, pendingRewards);

        emit onWithdrawRewards(msg.sender, pendingRewards);
    }

    /// @notice Users withdraws all the balance according their vesting, but they couldn't withdraw rewards any more with the witdrawRewards function
    function withdraw() external {
        require(balances[msg.sender].amount > 0, "NoStaked");
        require(balances[msg.sender].withdrawn < balances[msg.sender].amount, "Max");

        (uint256 userAmount, , , , , , uint256 pendingRewards, uint256 to) = _getData(msg.sender);
        uint256 tokensToSend = 0;
        if (balances[msg.sender].withdrawnFirst == false) {
            // This is the last time this user can get rewards, and the rest of the rewards are splitted for the other users.
            totalStakedAmount -= userAmount;
            totalRewards -= pendingRewards;

            uint256 tokens = _calculateTokens(msg.sender);
            balances[msg.sender].withdrawn += tokens;
            balances[msg.sender].lastUserWithdrawn = to;
            balances[msg.sender].withdrawnFirst = true;

            tokensToSend = tokens + pendingRewards;
            IERC20(token).safeTransfer(msg.sender, tokensToSend);
        } else {
            tokensToSend = _calculateTokens(msg.sender);
            balances[msg.sender].withdrawn += tokensToSend;
            balances[msg.sender].lastUserWithdrawn = to;

            IERC20(token).safeTransfer(msg.sender, tokensToSend);
        }

        emit onWithdraw(msg.sender, tokensToSend);
    }

    /// @notice Get the data for each user (to show in the frontend dapp)
    function getData(address _user) external view returns (uint256 userAmount, uint256 withdrawn, uint256 rewardsTokensPerSec, uint256 userTokensPerSec, uint256 lastRewardsWithdrawn, uint256 lastUserWithdrawn, uint256 pendingRewards, uint256 to) {
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
    function _calculateTokens(address _user) internal view returns (uint256) {
        InvestorType investorType = balances[msg.sender].investorType;
        uint256 vestingDays;
        if (investorType == InvestorType.ANGEL) vestingDays = 36 * 30 days;
        else if (investorType == InvestorType.SEED) vestingDays = 30 * 30 days;
        else if (investorType == InvestorType.STRATEGIC) vestingDays = 24 * 30 days;

        uint256 diffTime = block.timestamp - (balances[_user].lastUserWithdrawn == 0 ? stakeStartDate : balances[_user].lastUserWithdrawn);
        (, , , uint256 userTokensPerSec, , , , ) = _getData(_user);
        uint256 tokens = diffTime * userTokensPerSec; 
        if (balances[msg.sender].amount - balances[msg.sender].withdrawn < tokens) tokens = balances[msg.sender].amount - balances[msg.sender].withdrawn;

        return tokens;
    }

    /// Return contract data needed in the frontend
    function _getData(address _user) internal view returns (uint256 userAmount, uint256 withdrawn, uint256 rewardsTokensPerSec, uint256 userTokensPerSec, uint256 lastRewardsWithdraw, uint256 lastUserWithdrawn, uint256 pendingRewards, uint256 to) {
        userAmount = balances[_user].amount;
        withdrawn = balances[_user].withdrawn;
        lastRewardsWithdraw = balances[_user].lastRewardsWithdrawn;
        lastUserWithdrawn = balances[_user].lastUserWithdrawn;

        uint256 fromRewards = balances[_user].lastRewardsWithdrawn == 0 ? stakeStartDate : balances[_user].lastRewardsWithdrawn;
        to = block.timestamp > stakeEndDate ? stakeEndDate : block.timestamp;

        rewardsTokensPerSec = (totalRewards / (stakeEndDate - stakeStartDate)) * balances[_user].amount / totalStakedAmount;
        userTokensPerSec = (userAmount - (userAmount*15/100)) / (stakeEndDate - stakeStartDate);

        pendingRewards = balances[_user].withdrawnFirst == false ? (to - fromRewards) * rewardsTokensPerSec : 0;
    }
}