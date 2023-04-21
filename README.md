https://litlabgames.com/Whitepaper.pdf

Litlab PreStakingBox functions:
- First, we should call the function function getData(address _user) with the user address to know if it's an investor.
        uint256 userAmount, --> if > 0 is an investor
        uint256 withdrawn, --> Information. how many tokens has withdrawn the user
        uint256 rewardsTokensPerSec, // --> If we want to calculate a live indicator of rewards, this is the rewards per second.
        uint256 lastRewardsWithdrawn, // --> Information. Last time investor claimed rewards
        uint256 lastUserWithdrawn,  // --> Information. Last time the investor claimed its invested tokens
        uint256 pendingRewards  // --> Rewards that investor can claim.
- If withdrawn == 0, there's a button to claim the main investment, this first time the investor can claim 15% of the initial investment without any penalty claming the rewards and the button calls the function withdrawInitial()
- Otherwise the button claim investment calls the function withdraw(). The user will take the investment tokens but the rewards stop and pendingRewards when calling getData function will return always 0.
- There will be another button to claim the rewards that calls the function withdrawRewards(). The function will give the user the rewards at that moment and the pendingRewards counter will bet set to 0.
- The claim investment tokens button will be enabled until userAmount == withdrawn
- The claim rewards button will will be enabled while pendingRewards > 0
