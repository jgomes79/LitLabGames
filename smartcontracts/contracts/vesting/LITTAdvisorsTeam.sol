// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

contract LITTAdvisorsTeam is Ownable {
    using SafeERC20 for IERC20;

    uint256 immutable public ADVISORS_AMOUNT = 120000000 * 10 ** 18;
    uint256 immutable public TEAM_AMOUNT = 420000000 * 10 ** 18;

    mapping(address => uint256) private advisors;
    mapping(address => uint256) private advisorsWithdrawn;

    mapping(address => bool) private teamWallets;

    address[5] private approvalWallets;
    mapping(address => bool) private teamApprovals;
    uint8 numTeamApprovals;
    
    address public token;
    uint256 public listing_date;

    event onAdvisorWithdraw(address _wallet, uint256 _amount);
    event onEmergencyWithdraw();

    constructor(address _token, address[5] memory _approvalWallets) {
        token = _token;
        approvalWallets = _approvalWallets;
    }

    function setListingDate(uint256 _listingDate) external onlyOwner {
        listing_date = _listingDate;
    }

    function addAdvisor(address _wallet, uint256 _amount) external onlyOwner {
        advisors[_wallet] = _amount;
    }

    function removeAdvisor(address _wallet) external onlyOwner {
        delete advisors[_wallet];
    }

    function setApprovalWallets(address[5] calldata _approvalWallets) external {
        approvalWallets = _approvalWallets;
    }

    function advisorWithdraw() external {
        require(block.timestamp >= listing_date + 90 days, "TooEarly");
        require(advisors[msg.sender] - advisorsWithdrawn[msg.sender] > 0, "NotAllowed");

        uint256 start = listing_date + 90 days;
        uint256 end = start + (24 * 30 days);
        uint256 tokensPerSecond = ADVISORS_AMOUNT / (end - start);
        uint256 amountToWithdraw = ((block.timestamp - start) * tokensPerSecond) - advisorsWithdrawn[msg.sender];
        if (amountToWithdraw > advisors[msg.sender] - advisorsWithdrawn[msg.sender]) amountToWithdraw = advisors[msg.sender] - advisorsWithdrawn[msg.sender];
        advisorsWithdrawn[msg.sender] += amountToWithdraw;
        IERC20(token).safeTransfer(msg.sender, amountToWithdraw);

        emit onAdvisorWithdraw(msg.sender, amountToWithdraw);
    }

    function approveWithdraw() external {
        bool authorized;
        for (uint256 i=0; i<approvalWallets.length; i++) if (approvalWallets[i] == msg.sender) authorized = true;
        require(authorized, "NotAuthorized");

        if (teamApprovals[msg.sender] == false) {
            numTeamApprovals++;
            teamApprovals[msg.sender] = true;
        }
    }

    function teamWithdraw() external {
        require(numTeamApprovals >= 3, "NeedMoreApprovals");
        // TODO. Withdraw
    
        numTeamApprovals = 0;
        for (uint256 i=0; i<approvalWallets.length; i++) teamApprovals[approvalWallets[i]] = false;
    }

    function getAdvisorData(address _wallet) external view returns (uint256 amount, uint256 amountWithdrawn, uint256 end) {
        amount = advisors[_wallet];
        amountWithdrawn = advisorsWithdrawn[_wallet];
        end = listing_date + (27 * 30 days);
    }

    function getTokensInVesting() external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw();
    }
}
