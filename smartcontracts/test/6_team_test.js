const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const LITTAdvisorsTeam = artifacts.require("./LITTAdvisorsTeam.sol");

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

contract("LITTAdvisorsTeamContract tests", async(accounts) => {

    it("1. Setup should work", async () => {
        let advisorsteam = await LITTAdvisorsTeam.deployed();
    
        let now = Math.round(new Date().getTime() / 1000);
        let listingDate = now;
        await advisorsteam.setListingDate(listingDate);
    });

    it("2. Team should withdraw", async () => {
        let advisorsteam = await LITTAdvisorsTeam.deployed();

        let now = Math.round(new Date().getTime() / 1000);
        let listingDate = now + 30 * 24 * 3600;
        for (let i=0; i<365*5; i++) {
            await increaseTo(listingDate);
            console.log('SIMULATING DAY: ', new Date(listingDate*1000).toISOString());
            try {
                let tokensLeft = await advisorsteam.getTokensInContract();
                console.log('TOKENS WITHDRAW TEAM -> Tokens left: ', web3.utils.fromWei(tokensLeft.toString(),'ether'));   
                
                const tx = advisorsteam.teamWithdraw();

                tokensLeft = await advisorsteam.getTokensInContract();
                console.log('TOKENS WITHDRAW TEAM -> Tokens left: ', web3.utils.fromWei(tokensLeft.toString(),'ether'));   
            } catch(e) {
                console.log('ERROR WITHDRAW TEAM: ', e.toString());
            }
    
            listingDate += 30 * 86400;
        }
    });
});