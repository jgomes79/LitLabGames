// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";

import "@ganache/console.log/console.sol";

contract LITTVestingContract is Ownable {
    using SafeERC20 for IERC20;

    enum VestingType {
        ANGEL_ROUND,
        SEED_ROUND,
        STRATEGIC_ROUND,
        PUBLIC_ROUND,
        INITIAL_LIQUIDITY,
        NEW_GAMES,
        MARKETING,
        LIQUID_RESERVES,
        INGAME_REWARDS,
        FARMING,
        AIRDROPS,
        PRESTAKING,
        ADVISORS,
        TEAM
    }

    // TODO. Check if needed
    mapping(address => bool) public angel_round_investors;

    uint256 public angel_round = 105000000 * 10 ** 18;
    uint256 public seed_round = 175000000 * 10 ** 18;
    uint256 public strategic_round = 200000000 * 10 ** 18;
    uint256 public public_round = 95000000 * 10 ** 18;
    uint256 public initial_liquidity = 30000000 * 10 ** 18;
    uint256 public new_games = 690000000 * 10 ** 18;
    uint256 public marketing = 150000000 * 10 ** 18;
    uint256 public liquid_reserves = 210000000 * 10 ** 18;
    uint256 public ingame_rewards = 325000000 * 10 ** 18;
    uint256 public farming = 420000000 * 10 ** 18;
    uint256 public airdrops = 30000000 * 10 ** 18;
    uint256 public prestaking = 30000000 * 10 ** 18;
    uint256 public advisors = 120000000 * 10 ** 18;
    uint256 public team = 420000000 * 10 ** 18;

    address public token;
    address public wallet;
    uint256 public listing_date;

    mapping(uint8 => uint256) public withdrawnBalances;

    event onWithdrawToken(address _wallet, uint256 _amount);

    constructor(address _token, address _wallet) {
        token = _token;
        wallet = _wallet;
    }

    function setListingDate(uint256 _listingDate) external onlyOwner {
        listing_date = _listingDate;
    }

    function changeWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    function withdrawAngelRound() external {
        // Angel Round	15% at TGE, linearly over 36 months
        require(block.timestamp >= listing_date, "TooEarly");
        require(withdrawnBalances[uint8(VestingType.ANGEL_ROUND)] < angel_round, "MaxBalance");

        if (withdrawnBalances[uint8(VestingType.ANGEL_ROUND)] == 0) {
            uint256 amount = angel_round * 15 / 100;
            withdrawnBalances[uint8(VestingType.ANGEL_ROUND)] = amount;
            _sendTokens(wallet, amount);
        } else {
            uint256 timeDiff = block.timestamp - listing_date;
            uint256 month = (timeDiff / 30 days);   // Month number after listing.
            uint256 monthTranche = (angel_round - (angel_round * 15 / 100)) / 36;
            uint256 tranchesWithdrawed = (withdrawnBalances[uint8(VestingType.ANGEL_ROUND)] - (angel_round * 15 / 100)) / monthTranche;

            if (month > tranchesWithdrawed) {
                console.log("timeDiff: %d", timeDiff);
                console.log("month: %d", month);
                console.log("monthTranche: %d", monthTranche);
                console.log("tranchesWithdrawed: %d", tranchesWithdrawed);
                console.log("withdrawBalances: %d", withdrawnBalances[uint8(VestingType.ANGEL_ROUND)]);

                uint256 numTranches = month - tranchesWithdrawed;
                uint256 availableAmount = monthTranche * numTranches;

                if (withdrawnBalances[uint8(VestingType.ANGEL_ROUND)] + availableAmount > angel_round) {
                    availableAmount = angel_round - withdrawnBalances[uint8(VestingType.ANGEL_ROUND)];
                } 
                withdrawnBalances[uint8(VestingType.ANGEL_ROUND)] += availableAmount;
                _sendTokens(wallet, availableAmount);
            }
        }
    }

    function withdrawSeedRound() external {
        // Seed Round	15% at TGE, linearly over 30 months
    }

    function withdrawStrategicRound() external {
        // Strategic round	15% at TGE, linearly over 24 months
    }

    function withdrawPublicRound() external {
        // Sin vesting. Esto se le da al exchange
    }

    function withdrawInitialLiquidity() external {
        // No vesting
        require(block.timestamp >= listing_date, "TooEarly");
        require(withdrawnBalances[uint8(VestingType.INITIAL_LIQUIDITY)] <= initial_liquidity, "MaxBalance");
    }

    function withdrawNewGames() external {
        // New Games 12-18 months cliff based on game releases
    }

    function withdrawMarketing() external {
        // Marketing 5% at TGE, linearly over 18 months
        require(block.timestamp >= listing_date, "TooEarly");
        require(withdrawnBalances[uint8(VestingType.MARKETING)] < marketing, "MaxBalance");

        if (withdrawnBalances[uint8(VestingType.MARKETING)] == 0) {
            uint256 amount = marketing * 5 / 100;
            withdrawnBalances[uint8(VestingType.MARKETING)] = amount;
            _sendTokens(wallet, amount);
        } else {
            uint256 timeDiff = block.timestamp - listing_date;
            uint256 month = (timeDiff / 30 days);   // Month number after listing.
            uint256 monthTranche = (marketing - (marketing * 5 / 100)) / 18;
            uint256 tranchesWithdrawed = (withdrawnBalances[uint8(VestingType.MARKETING)] - (marketing * 5 / 100)) / monthTranche;

            if (month > tranchesWithdrawed) {
                console.log("timeDiff: %d", timeDiff);
                console.log("month: %d", month);
                console.log("monthTranche: %d", monthTranche);
                console.log("tranchesWithdrawed: %d", tranchesWithdrawed);
                console.log("withdrawBalances: %d", withdrawnBalances[uint8(VestingType.MARKETING)]);

                uint256 numTranches = month - tranchesWithdrawed;
                uint256 availableAmount = monthTranche * numTranches;

                if (withdrawnBalances[uint8(VestingType.MARKETING)] + availableAmount > marketing) {
                    availableAmount = marketing - withdrawnBalances[uint8(VestingType.MARKETING)];
                } 
                withdrawnBalances[uint8(VestingType.MARKETING)] += availableAmount;
                _sendTokens(wallet, availableAmount);
            }
        }
    }

    function withdrawLiquidReserves() external {
        // Liquid Reserves	Vesting linearly over 24 months
    }

    function withdrawIngameRewards() external {
        // InGame rewards	Over 48 months
    }

    function withdrawFarming() external {
        // Farming	Over 54 months
    }

    function withdrawAirdrops() external {
        // Airdrops	10% at TGE, linearly over 12 months
    }

    function withdrawPrestaking() external {
        // PreStaking	Over 54 months
    }

    function withdrawAdvisors() external {
        // Advisors	3 months cliff + 24 months vesting
    }

    function withdrawTeam() external {
        // Team	6 months cliff + 42 months linear vesting
    }

    function getTokensInVesting() external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function _sendTokens(address _wallet, uint256 _amount) internal {
        IERC20(token).transfer(_wallet, _amount);

        emit onWithdrawToken(_wallet, _amount);
    }

/*
    function withdrawFoundationTokens() external {
        require(block.timestamp >= listingDate + 365 days, "TooEarly");
        require(withdrawnBalances[uint256(WalletType.Foundation)] < FOUNDATION_MAX, "MaxBalance");

        uint256 timeDiff = block.timestamp - (listingDate + 365 days);
        uint256 month = (timeDiff / 30 days) + 1;   // Month number after listing + 1 year
        uint256 monthTranche = TEAM_MAX / 36;
        uint256 tranchesWithdrawed = withdrawnBalances[uint256(WalletType.Foundation)] / monthTranche;

        if (month > tranchesWithdrawed) {
            uint256 numTranches = month - tranchesWithdrawed;
            uint256 availableAmount = monthTranche * numTranches;

            withdrawnBalances[uint256(WalletType.Foundation)] += availableAmount;
            _sendTokens(uint256(WalletType.Foundation), availableAmount);
        }
    }
*/
}
