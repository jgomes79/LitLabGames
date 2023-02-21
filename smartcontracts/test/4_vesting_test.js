const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const LITTVestingContract = artifacts.require("./LITTVestingContract.sol");

const BN = web3.utils.BN;
const { promisify } = require('util');

// Returns the time of the last mined block in seconds
async function latest () {
    const block = await web3.eth.getBlock('latest');
    return new BN(block.timestamp);
}

function advanceBlock () {
    return promisify(web3.currentProvider.send.bind(web3.currentProvider))({
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: new Date().getTime(),
    });
}

// Increases ganache time by the passed duration in seconds
async function increase (duration) {
    if (!BN.isBN(duration)) {
        duration = new BN(duration);
    }
  
    if (duration.isNeg()) throw Error(`Cannot increase time by a negative amount (${duration})`);
  
    await promisify(web3.currentProvider.send.bind(web3.currentProvider))({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [duration.toNumber()],
        id: new Date().getTime()
    });
  
    await advanceBlock();
}

async function increaseTo (target) {
    if (!BN.isBN(target)) {
        target = new BN(target);
    }
  
    const now = (await latest());
    if (target.lt(now)) throw Error(`Cannot increase current time (${now}) to a moment in the past (${target})`);
    const diff = target.sub(now);
    return increase(diff);
}

contract("LITTVestingContract tests", async(accounts) => {

    it("1. Vesting should work", async () => {
        let token = await LitlabGamesToken.deployed();
        let vesting = await LITTVestingContract.deployed();
    
        let now = Math.round(new Date().getTime() / 1000);
        let listingDate = now;
        await vesting.setListingDate(listingDate);

        listingDate +=  30 * 24 * 3600;
        for (let i=0; i<365*5; i++) {
            await increaseTo(listingDate);
            console.log('SIMULATING DAY: ', new Date(listingDate*1000).toISOString());
            try {
                let tokensLeft = await vesting.getTokensInVesting();
                console.log('TOKENS WITHDRAW -> Tokens left: ', web3.utils.fromWei(tokensLeft.toString(),'ether'));   
                
                const txNewGames = await vesting.withdrawNewGames(web3.utils.toWei('100000'));
                const txMarketing = await vesting.withdrawMarketing();
                const txLiquidReserves = await vesting.withdrawLiquidReserves();
                const txAirdrops = await vesting.withdrawAirdrops();
                const txInGameRewards = await vesting.withdrawInGameRewards(web3.utils.toWei('300000'));
                const txInFarming = await vesting.withdrawFarming(web3.utils.toWei('300000'));

                tokensLeft = await vesting.getTokensInVesting();
                console.log('TOKENS WITHDRAW -> Tokens left: ', web3.utils.fromWei(tokensLeft.toString(),'ether'));   
            } catch(e) {
                console.log('ERROR: ', e.toString());
                let tokensLeft = await vesting.getTokensInVesting();
                console.log('TOKENS WITHDRAW FOR TEAM -> Tokens left: ', web3.utils.fromWei(tokensLeft.toString(),'ether'));   
            }
    
            listingDate += 86400;
        }
    
        const tokensAccount = await token.balanceOf(accounts[0]);
        console.log('Tokens recoverd account: ', web3.utils.fromWei(tokensAccount,'ether'));
    });
});