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

        await advisorsteam.addAdvisor(accounts[1], web3.utils.toWei('1000000'));
        await advisorsteam.addAdvisor(accounts[2], web3.utils.toWei('2000000'));
        await advisorsteam.addAdvisor(accounts[3], web3.utils.toWei('3000000'));
        await advisorsteam.addAdvisor(accounts[4], web3.utils.toWei('4000000'));
        await advisorsteam.addAdvisor(accounts[5], web3.utils.toWei('5000000'));
    });

   it("2. Advisor should withdraw", async () => {
        let advisorsteam = await LITTAdvisorsTeam.deployed();

        let tokensInitial = await advisorsteam.getTokensInContract();
        tokensInitial = web3.utils.fromWei(tokensInitial.toString(),'ether');
        console.log('TOKENS WITHDRAW ADVISORS -> Tokens in contract: ', tokensInitial);   

        let now = Math.round(new Date().getTime() / 1000);
        let listingDate = now + 30 * 24 * 3600;
        for (let i=0; i<36; i++) {
            await increaseTo(listingDate);
            console.log('SIMULATING DAY: ', new Date(listingDate*1000).toISOString());
            try {
                await advisorsteam.advisorWithdraw({from: accounts[1]});
                await advisorsteam.advisorWithdraw({from: accounts[2]});
                await advisorsteam.advisorWithdraw({from: accounts[3]});
                await advisorsteam.advisorWithdraw({from: accounts[4]});
                await advisorsteam.advisorWithdraw({from: accounts[5]});
            } catch(e) {
                console.log('ERROR WITHDRAW ADVISORS: ', e.toString());
            }
    
            listingDate += 30 * 86400;
        }

        let tokensLeft = await advisorsteam.getTokensInContract();
        tokensLeft = web3.utils.fromWei(tokensLeft.toString(),'ether');
        console.log('TOKENS WITHDRAW ADVISORS -> Tokens left: ', tokensLeft);   

        // The 5 advisors withdraw 15.000.000 tokens according to test 1. The difference of tokens should be 15.000.000
        const diff = tokensInitial - tokensLeft;
        assert.equal(diff, 15000000);
    });
});