// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/Ownable.sol";

contract LITTVestingContract is Ownable {
    enum VestingType {
        ANGEL_ROUND = 1,
        SEED_ROUND = 2,
        STRATEGIC_ROUND = 3,
        PUBLIC_ROUND = 4,
        INITIAL_LIQUIDITY = 5,
        NEW_GAMES = 6,
        MARKETING = 7,
        LIQUID_RESERVES = 8,
        INGAME_REWARDS = 9,
        MARKETING = 10,
        LIQUID_RESERVES = 11,
        INGAME_REWARDS = 12,
        FARMING = 13,
        AIRDROPS = 14,
        PRESTAKING = 15,
        ADVISORS = 16,
        TEAM = 17
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

    address public wallet;
    uint256 public listing_date;

    mapping(uint8 => uint256) public withdrawnBalances;

    constructor(address _wallet) {  
        wallet = _wallet;
    }

    function setListingDate(uint256 _listingDate) external onlyOwner {
        listingDate = _listingDate;
    }

    function changeWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

    function withdrawAngelRound() external {
        // Angel Round	15% at TGE, linearly over 36 months
        require(block.timestamp >= listingDate, "TooEarly");
        require(withdrawnBalances[VestingType.ANGEL_ROUND)] <= angel_round, "MaxBalance");

        if (withdrawnBalances[VestingType.ANGEL_ROUND) == 0) {
            uint256 amount = angel_round * 15 / 100;
            withdrawnBalances[VestingType.ANGEL_ROUND)] = amount;
            _sendTokens(wallet, amount);
        } else {
            uint256 timeDiff = block.timestamp - listingDate;
            uint256 month = (timeDiff / 30 days);   // Month number after listing.
            uint256 monthTranche = angel_round - (angel_round * 15 / 100) / 36;
            uint256 tranchesWithdrawed = withdrawnBalances[VestingType.ANGEL_ROUND] / monthTranche;

            if (month > tranchesWithdrawed) {
                uint256 numTranches = month - tranchesWithdrawed;
                uint256 availableAmount = monthTranche * numTranches;

                withdrawnBalances[VestingType.ANGEL_ROUND] += availableAmount;
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
        // Public round	33% unlock at TGE, vesting 2 months
    }

    function withdrawInitialLiquidity() external {
        // No vesting
        require(block.timestamp >= listingDate, "TooEarly");
        require(withdrawnBalances[VestingType.INITIAL_LIQUIDITY)] <= initial_liquidity, "MaxBalance");
    }

    function withdrawNewGames() external {
        // New Games 12-18 months cliff based on game releases
    }

    function withdrawMarketing() external {
        // Marketing 5% at TGE, linearly over 18 months
    }

    function withdrawLiquidReserves() external {
        // Liquid Reserves	Vesting linearly over 24 months
    }

    function withdrawLiquidReserves() external {
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

    function withdrawAdvisors() external {
        // Team	6 months cliff + 42 months linear vesting
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
