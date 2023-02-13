// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

/// @title LITTVestingContract
/// @notice Vesting contract for LitlabGames token
contract LITTVestingContract is Ownable {
    using SafeERC20 for IERC20;

    enum VestingType {
        NEW_GAMES,
        MARKETING,
        LIQUID_RESERVES,
        AIRDROPS,
        INGAME_REWARDS,
        FARMING
    }

    uint256 immutable public NEW_GAMES_AMOUNT = 690000000 * 10 ** 18;
    uint256 immutable public MARKETING_AMOUNT = 150000000 * 10 ** 18;
    uint256 immutable public LIQUID_RESERVES_AMOUNT = 210000000 * 10 ** 18;
    uint256 immutable public AIRDROPS_AMOUNT = 30000000 * 10 ** 18;
    uint256 immutable public INGAME_REWARDS_AMOUNT = 325000000 * 10 ** 18;
    uint256 immutable public FARMING_AMOUNT = 420000000 * 10 ** 18;

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

    /// @notice Set the token address, the withdraw wallet and the vesting amounts
    constructor(address _token, address _wallet) {
        token = _token;
        wallet = _wallet;

        vestingData[VestingType.NEW_GAMES] = VestingData({
            _amount: NEW_GAMES_AMOUNT,
            _months: 0,
            _cliffMonths: 12,
            _TGEPercentage: 0
        });
        vestingData[VestingType.MARKETING] = VestingData({
            _amount: MARKETING_AMOUNT,
            _months: 18,
            _cliffMonths: 0,
            _TGEPercentage: 5
        });
        vestingData[VestingType.LIQUID_RESERVES] = VestingData({
            _amount: LIQUID_RESERVES_AMOUNT,
            _months: 24,
            _cliffMonths: 0,
            _TGEPercentage: 0
        });
        vestingData[VestingType.AIRDROPS] = VestingData({
            _amount: AIRDROPS_AMOUNT,
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

    function withdrawNewGames(uint256 _amount) external {
        // Free Withdraw
        require(withdrawnBalances[VestingType.NEW_GAMES] + _amount > NEW_GAMES_AMOUNT, "Max");
        _sendTokens(wallet, VestingType.NEW_GAMES, _amount);
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

    function withdrawInGameRewards(uint256 _amount) external {
        // Free withdraw
        require(withdrawnBalances[VestingType.INGAME_REWARDS] + _amount > INGAME_REWARDS_AMOUNT, "Max");
        _sendTokens(wallet, VestingType.INGAME_REWARDS, _amount);
    }

    function withdrawFarming(uint256 _amount) external {
        // Free withdraw
        require(withdrawnBalances[VestingType.FARMING] + _amount > FARMING_AMOUNT, "Max");
        _sendTokens(wallet, VestingType.FARMING, _amount);
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
