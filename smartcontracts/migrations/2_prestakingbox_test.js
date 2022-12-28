const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const LitlabPreStakingBox = artifacts.require("./LitlabPreStakingBox.sol");

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

    let stakingBox = await LitlabPreStakingBox.deployed();
    console.log('LitlabPreStakingBox deployed:', stakingBox.address);

    let now = Math.round(new Date().getTime() / 1000);

    for (let i=0; i<365*5; i++) {
        await increaseTo(now);
        console.log('PRESTAKING BOX SIMULATION: ', new Date(now*1000).toISOString());
        try {
            //const x = await stakingBox.getData(accounts[1]);
            //console.log({ userTokensPerSec: x.userTokensPerSec.toString(), amount: x.amount.toString(), lastRewardsWithdraw: x.lastRewardsWithdraw.toString(), rewards: x.rewards.toString() });
            const tx1 = await stakingBox.withdrawRewards({from: accounts[1]});
            const tx2 = await stakingBox.withdrawRewards({from: accounts[2]});
            const tx3 = await stakingBox.withdrawRewards({from: accounts[3]});
            const tx4 = await stakingBox.withdrawRewards({from: accounts[4]});
            const tx5 = await stakingBox.withdrawRewards({from: accounts[5]});
            const tx6 = await stakingBox.withdrawRewards({from: accounts[6]});
            const tx7 = await stakingBox.withdrawRewards({from: accounts[7]});
            const tx8 = await stakingBox.withdrawRewards({from: accounts[8]});
            //console.log({ user: tx.logs[0].args._user, amount: web3.utils.fromWei(tx.logs[0].args._amount.toString(),'ether') });
            //const tx = await stakingBox.withdrawInitial({from: accounts[1]});
            //console.log(tx.logs[0].args);
        } catch(e) {
            console.log('CATCH PRESTAKING BOX SIMULATION: ', new Date(now*1000).toISOString(), e.toString());
        }
        let tokensLeft = await stakingBox.getTokensInContract();
        console.log('TOKENS LEFT IN CONTRACT: ', web3.utils.fromWei(tokensLeft.toString(),'ether'));   

        now += (86400 * 30);

        let tokensAccount = await token.balanceOf(accounts[1]);
        console.log('Accounts1 tokens: ', web3.utils.fromWei(tokensAccount.toString(),'ether'));
        tokensAccount = await token.balanceOf(accounts[2]);
        console.log('Accounts2 tokens: ', web3.utils.fromWei(tokensAccount.toString(),'ether'));
        tokensAccount = await token.balanceOf(accounts[3]);
        console.log('Accounts3 tokens: ', web3.utils.fromWei(tokensAccount.toString(),'ether'));
        tokensAccount = await token.balanceOf(accounts[4]);
        console.log('Accounts4 tokens: ', web3.utils.fromWei(tokensAccount.toString(),'ether'));
        tokensAccount = await token.balanceOf(accounts[5]);
        console.log('Accounts5 tokens: ', web3.utils.fromWei(tokensAccount.toString(),'ether'));
        tokensAccount = await token.balanceOf(accounts[6]);
        console.log('Accounts6 tokens: ', web3.utils.fromWei(tokensAccount.toString(),'ether'));
        tokensAccount = await token.balanceOf(accounts[7]);
        console.log('Accounts7 tokens: ', web3.utils.fromWei(tokensAccount.toString(),'ether'));
        tokensAccount = await token.balanceOf(accounts[8]);
        console.log('Accounts8 tokens: ', web3.utils.fromWei(tokensAccount.toString(),'ether'));
    }
}

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
};