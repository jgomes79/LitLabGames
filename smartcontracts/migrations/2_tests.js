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

async function doDeploy(deployer, network, accounts) {
    let token = await LitlabGamesToken.deployed();
    console.log('LitlabGamesToken deployed:', token.address);

    let vesting = await LITTVestingContract.deployed();
    console.log('LITTVestingContract deployed:', vesting.address);

    let now = Math.round(new Date().getTime() / 1000);
    let listingDate = now;
    await vesting.setListingDate(listingDate);

    for (let i=0; i<365*5; i++) {
        await increaseTo(listingDate);
        console.log('SIMULATING DAY: ', new Date(listingDate*1000).toISOString());
        try {
            const txAngelRound = await vesting.withdrawMarketing();
            if (txAngelRound.receipt.logs.length > 0) {
                let tokensLeft = await vesting.getTokensInVesting();
                console.log('TOKENS WITHDRAW FOR TEAM -> Tokens left: ', web3.utils.fromWei(tokensLeft.toString(),'ether'));   
            }
        } catch(e) {
            console.log('ERROR TEAM: ', new Date(listingDate*1000).toISOString(), e.toString());
            let tokensLeft = await vesting.getTokensInVesting();
            console.log('TOKENS WITHDRAW FOR TEAM -> Tokens left: ', web3.utils.fromWei(tokensLeft.toString(),'ether'));   
        }

        listingDate += 86400;
    }

    const tokensAccount = await token.balanceOf(accounts[0]);
    console.log('Tokens recoverd account: ', web3.utils.fromWei(tokensAccount,'ether'));
}

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
};