// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

contract LITTVestingContract is Ownable {
    using SafeERC20 for IERC20;

    enum VestingType {
        NEW_GAMES,
        MARKETING,
        LIQUID_RESERVES,
        AIRDROPS
    }

    struct VestingData {
        uint256 _amount;
        uint24 _TGEPercentage;
        uint8 _months;
        uint8 _cliffMonths;
    }

    mapping(VestingType => VestingData) private vestingData;
    mapping(VestingType => uint256) public withdrawnBalances;

    address public token;
    address public wallet;
    uint256 public listing_date;

    event onWithdrawToken(address _wallet, uint256 _amount);
    event onEmergencyWithdraw();

    constructor(address _token, address _wallet) {
        token = _token;
        wallet = _wallet;

        vestingData[VestingType.NEW_GAMES] = VestingData({
            _amount: 690000000 * 10 ** 18,
            _months: 0,
            _cliffMonths: 12,
            _TGEPercentage: 0
        });
        vestingData[VestingType.MARKETING] = VestingData({
            _amount: 150000000 * 10 ** 18,
            _months: 18,
            _cliffMonths: 0,
            _TGEPercentage: 5
        });
        vestingData[VestingType.LIQUID_RESERVES] = VestingData({
            _amount: 210000000 * 10 ** 18,
            _months: 24,
            _cliffMonths: 0,
            _TGEPercentage: 0
        });
        vestingData[VestingType.AIRDROPS] = VestingData({
            _amount: 210000000 * 10 ** 18,
            _months: 12,
            _cliffMonths: 0,
            _TGEPercentage: 10
        });
    }

    function setListingDate(uint256 _listingDate) external onlyOwner {
        listing_date = _listingDate;
    }

    function changeWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    function getVestingData(uint8 _vestingType) external view returns (uint256 amount, uint24 TGEPercentage, uint8 months, uint8 cliffMonths, uint256 withdrawn) {
        VestingData memory data = vestingData[VestingType(_vestingType)];
        amount = data._amount;
        TGEPercentage = data._TGEPercentage;
        months = data._months;
        cliffMonths = data._cliffMonths;
        withdrawn = withdrawnBalances[VestingType(_vestingType)];
    }

    function withdrawNewGames() external {
        // New Games 12-18 months cliff based on game releases
        _executeVesting(VestingType.NEW_GAMES);
    }

    function withdrawMarketing() external {
        // Marketing 5% at TGE, linearly over 18 months
        _executeVesting(VestingType.MARKETING);
    }

    function withdrawLiquidReserves() external {
        // Liquid ReservesVesting linearly over 24 months
        _executeVesting(VestingType.LIQUID_RESERVES);
    }

    function withdrawAirdrops() external {
        // Airdrops	10% at TGE, linearly over 12 months
        _executeVesting(VestingType.AIRDROPS);
    }

    function getTokensInVesting() external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, balance);

        emit onEmergencyWithdraw();
    }

    function _executeVesting(VestingType _vestingType) internal {
        VestingData memory data = vestingData[_vestingType];
        require(block.timestamp >= listing_date + (data._cliffMonths * 30 days), "TooEarly");
        require(withdrawnBalances[_vestingType] < data._amount, "MaxBalance");

        if ((data._TGEPercentage > 0) && (withdrawnBalances[_vestingType] == 0)) {
            uint256 amountToWithdraw = data._TGEPercentage * data._amount / 100;
            _sendTokens(wallet, _vestingType, amountToWithdraw);
        } else {
            uint256 start = listing_date + (data._cliffMonths * 30 days);
            uint256 end = start + (data._months * 30 days);
            uint256 tokensPerSecond = data._amount / (end - start);
            uint256 amountToWithdraw = ((block.timestamp - start) * tokensPerSecond) - withdrawnBalances[_vestingType];
            if (amountToWithdraw > data._amount - withdrawnBalances[_vestingType]) amountToWithdraw = data._amount - withdrawnBalances[_vestingType];
            _sendTokens(wallet, _vestingType, amountToWithdraw);
        }
    }

    function _sendTokens(address _wallet, VestingType _vestingType, uint256 _amount) internal {
        withdrawnBalances[_vestingType] += _amount;
        IERC20(token).safeTransfer(_wallet, _amount);

        emit onWithdrawToken(_wallet, _amount);
    }
}
