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
        let vesting = await LITTVestingContract.deployed();
    
        let now = Math.round(new Date().getTime() / 1000);
        let listingDate = now + 3600;
        await vesting.setListingDate(listingDate);

        for (let i=0; i<36; i++) {
            await increaseTo(listingDate);
            console.log('SIMULATING DAY: ', new Date(listingDate*1000).toISOString());

            try { 
                await vesting.withdrawNewGames(web3.utils.toWei('100000')); 
            } catch(e) { console.log('NEW_GAMES ERROR: ', e.toString()); }
            const tx1 = await vesting.getVestingData(0); 
            console.log('NEW_GAMES:', web3.utils.fromWei(tx1.withdrawn.toString(),'ether'));
            
            try { 
                await vesting.withdrawMarketing();
            } catch(e) { console.log('MARKETING ERROR: ', e.toString()); } 
            const tx2 = await vesting.getVestingData(1); 
            console.log('MARKETING:', web3.utils.fromWei(tx2.withdrawn.toString(),'ether')); 
            
            try { 
                await vesting.withdrawLiquidReserves();
            } catch(e) { /*console.log('LIQUID_RESERVES ERROR: ', e.toString()); */}
            const tx3 = await vesting.getVestingData(2);
            console.log('LIQUID_RESERVES:', web3.utils.fromWei(tx3.withdrawn.toString(),'ether')); 
            
            try { 
                await vesting.withdrawAirdrops(); 
            } catch(e) { console.log('AIRDROPS ERROR: ', e.toString()); }
            const tx4 = await vesting.getVestingData(3); 
            console.log('AIRDROPS:', web3.utils.fromWei(tx4.withdrawn.toString(),'ether')); 
            
            try { 
                await vesting.withdrawInGameRewards(web3.utils.toWei('300000'));
            } catch(e) { console.log('INGAME_REWARDS ERROR: ', e.toString()); }
            const tx5 = await vesting.getVestingData(4); 
            console.log('INGAME_REWARDS:', web3.utils.fromWei(tx5.withdrawn.toString(),'ether')); 
            
            try { 
                await vesting.withdrawFarming(web3.utils.toWei('300000'));
            } catch(e) { console.log('FARMING ERROR: ', e.toString()); }
            const tx6 = await vesting.getVestingData(5); 
            console.log('FARMING:', web3.utils.fromWei(tx6.withdrawn.toString(),'ether')); 
    
            listingDate += (30 * 86400);
        }

        // At the end of the vesting we check the results
        // tx1: NewGames. We withdrawn 100.000 tokens 36 times, so the balance must be 3.600.000
        const tx1 = await vesting.getVestingData(0); 
        const balance1 = await web3.utils.fromWei(tx1.withdrawn.toString(),'ether');
        assert.equal(balance1, 3600000);
        //tx2: Marketing. We withdrawn all the tokens, so the balance should be 150.000.000
        const tx2 = await vesting.getVestingData(1); 
        const balance2 = await web3.utils.fromWei(tx2.withdrawn.toString(),'ether');
        assert.equal(balance2, 150000000); 
        //tx3: Liquid reserves. We withdrawn all the tokens, so the balance should be 210.000.000
        const tx3 = await vesting.getVestingData(2); 
        const balance3 = await web3.utils.fromWei(tx3.withdrawn.toString(),'ether');
        assert.equal(balance3, 210000000); 
        //tx4: Airdrops. We withdrawn all the tokens, so the balance should be 30.000.000
        const tx4 = await vesting.getVestingData(3); 
        const balance4 = await web3.utils.fromWei(tx4.withdrawn.toString(),'ether');
        assert.equal(balance4, 30000000); 
        //tx5: InGameRewards. We withdrawn 300.000 36 times, so the balance should be 10.800.000
        const tx5 = await vesting.getVestingData(4); 
        const balance5 = await web3.utils.fromWei(tx5.withdrawn.toString(),'ether');
        assert.equal(balance5, 10800000); 
        //tx6: Farming. We withdrawn 300.000 36 times, so the balance should be 10.800.000
        const tx6 = await vesting.getVestingData(5); 
        const balance6 = await web3.utils.fromWei(tx6.withdrawn.toString(),'ether');
        assert.equal(balance6, 10800000); 
    });
});