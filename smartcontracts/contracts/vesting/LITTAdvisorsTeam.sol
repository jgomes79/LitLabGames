// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

contract LITTAdvisorsTeam is Ownable {
    using SafeERC20 for IERC20;

    uint256 immutable private ADVISORS_AMOUNT = 120000000 * 10 ** 18;

    mapping(address => uint256) private advisors;
    mapping(address => uint256) private advisorsWithdrawn;
    mapping(address => uint256) public team;

    address public token;
    uint256 public listing_date;

    event onAdvisorWithdraw(address _wallet, uint256 _amount);
    event onEmergencyWithdraw();

    constructor(address _token) {
        token = _token;
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

    function getTokensInVesting() external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw();
    }
}
