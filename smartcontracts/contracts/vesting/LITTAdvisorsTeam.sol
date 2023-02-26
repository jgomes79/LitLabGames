// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

/// @title Vesting contract for advisors and team tokens
contract LITTAdvisorsTeam is Ownable {
    using SafeERC20 for IERC20;

    uint256 immutable public ADVISORS_AMOUNT = 120000000 * 10 ** 18;
    uint256 immutable public TEAM_AMOUNT = 420000000 * 10 ** 18;
    uint8 immutable private MAX_SIGNATURES_TEAM = 3;

    mapping(address => uint256) private advisors;
    mapping(address => uint256) private advisorsWithdrawn;
    mapping(address => uint256) private advisorsLastWithdrawn;

    mapping(address => bool) private teamWallets;
    address public teamWallet;
    uint256 public teamWithdrawn;
    uint256 public teamLastWithdraw;

    address[5] private approvalWallets;
    mapping(address => bool) private teamApprovals;
    uint8 numTeamApprovals;
    
    address public token;
    uint256 public listing_date;

    event onAdvisorWithdraw(address _wallet, uint256 _amount);
    event onTeamWithdraw(address _wallet, uint256 _amount);
    event onEmergencyWithdraw();

    /// @notice Constructor
    /// @param _token LitlabGames token address
    /// @param _teamWallet Wallet where team tokens are sent when withdrawn
    /// @param _approvalWallets For team tokens, an approval of 3/5 wallets will be required
    constructor(address _token, address _teamWallet, address[5] memory _approvalWallets) {
        token = _token;
        teamWallet = _teamWallet;
        approvalWallets = _approvalWallets;
    }

    /// @notice Set listing date to start the vesting period
    function setListingDate(uint256 _listingDate) external onlyOwner {
        listing_date = _listingDate;
    }

    /// @notice Add a new advisor
    function addAdvisor(address _wallet, uint256 _amount) external onlyOwner {
        advisors[_wallet] = _amount;
    }

    /// @notice Remove an advisor
    function removeAdvisor(address _wallet) external onlyOwner {
        delete advisors[_wallet];
    }

    /// @notice Change the approval wallets
    function setApprovalWallets(address[5] calldata _approvalWallets) external onlyOwner {
        approvalWallets = _approvalWallets;
    }

    /// @notice Set new team wallet
    function setTeamWallet(address _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    /// @notice The advisors can withdraw their tokens according to the vesting
    function advisorWithdraw() external {
        require(block.timestamp >= listing_date + 90 days, "TooEarly");
        require(advisors[msg.sender] - advisorsWithdrawn[msg.sender] > 0, "NotAllowed");

        uint256 start = listing_date + 90 days;
        uint256 end = start + (24 * 30 days);
        uint256 from = advisorsLastWithdrawn[msg.sender] == 0 ? start : advisorsLastWithdrawn[msg.sender];
        uint256 to = block.timestamp > end ? end : block.timestamp;
        uint256 tokensPerSecond = advisors[msg.sender] / (end - start);
        require(to > from, "Expired");

        uint256 amountToWithdraw = (to - from) * tokensPerSecond;
        if (amountToWithdraw > advisors[msg.sender] - advisorsWithdrawn[msg.sender]) amountToWithdraw = advisors[msg.sender] - advisorsWithdrawn[msg.sender];

        advisorsWithdrawn[msg.sender] += amountToWithdraw;
        advisorsLastWithdrawn[msg.sender] = block.timestamp;
        IERC20(token).safeTransfer(msg.sender, amountToWithdraw);

        emit onAdvisorWithdraw(msg.sender, amountToWithdraw);
    }

    /// @notice Function for approve the team tokens withdraw
    function approveTeamWithdraw() external {
        bool authorized;
        for (uint256 i=0; i<approvalWallets.length; i++) if (approvalWallets[i] == msg.sender) authorized = true;
        require(authorized, "NotAuthorized");

        if (teamApprovals[msg.sender] == false) {
            numTeamApprovals++;
            teamApprovals[msg.sender] = true;
        }
    }

    /// @notice The team can withdraw their tokens according to the vesting
    function teamWithdraw() external {
        require(block.timestamp >= listing_date + 180 days, "TooEarly");
        require(numTeamApprovals >= MAX_SIGNATURES_TEAM, "NeedMoreApprovals");
        require(TEAM_AMOUNT - teamWithdrawn > 0, "NotAllowed");
    
        numTeamApprovals = 0;
        for (uint256 i=0; i<approvalWallets.length; i++) delete teamApprovals[approvalWallets[i]];
        
        uint256 start = listing_date + 180 days;
        uint256 end = start + (42 * 30 days);
        uint256 from = teamLastWithdraw == 0 ? start : teamLastWithdraw;
        uint256 to = block.timestamp > end ? end : block.timestamp;
        uint256 tokensPerSecond = TEAM_AMOUNT / (end - start);
        require(to > from, "Expired");

        uint256 amountToWithdraw = (to - from) * tokensPerSecond;
        if (amountToWithdraw > TEAM_AMOUNT - teamWithdrawn) amountToWithdraw = TEAM_AMOUNT - teamWithdrawn;
        
        teamWithdrawn += amountToWithdraw;
        teamLastWithdraw = block.timestamp;
        IERC20(token).safeTransfer(teamWallet, amountToWithdraw);

        emit onTeamWithdraw(msg.sender, amountToWithdraw);
    }

    /// @notice Get data to the dapp
    function getAdvisorData(address _wallet) external view returns (uint256 amount, uint256 amountWithdrawn, uint256 end) {
        amount = advisors[_wallet];
        amountWithdrawn = advisorsWithdrawn[_wallet];
        end = listing_date + (27 * 30 days);
    }

    /// @notice Quick way to know how many tokens are pending in the contract
    function getTokensInContract() external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice If there's any problem, contract owner can withdraw all funds (are advisors and team funds)
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw();
    }
}
