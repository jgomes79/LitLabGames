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

async function withdrawRewards(from, now) {
    try {
        let stakingBox = await LitlabPreStakingBox.deployed();
        //const data = await stakingBox.getData(from);
/*
        console.log({
            userAmount: web3.utils.fromWei(data.userAmount.toString(),'ether'),
            withdrawn: web3.utils.fromWei(data.withdrawn.toString(),'ether'),
            rewardsTokensPerSec: web3.utils.fromWei(data.rewardsTokensPerSec.toString(),'ether'),
            lastRewardsWithdrawn: data.lastRewardsWithdrawn.toString(),
            lastUserWithdrawn: data.lastUserWithdrawn.toString(),
            pendingRewards: web3.utils.fromWei(data.pendingRewards.toString(),'ether'),
            to: new Date(data.to * 1000).toString()
        });
*/
        const tx = await stakingBox.withdrawRewards({from: from});
        //console.log({ user: tx.logs[0].args._user, rewards: web3.utils.fromWei(tx.logs[0].args._rewards.toString(),'ether') });

    } catch(e) {
        console.log('CATCH PRESTAKING BOX SIMULATION: ', new Date(now*1000).toISOString(), e.toString());
    }
}

async function withdraw(from, now) {
    try {
        let stakingBox = await LitlabPreStakingBox.deployed();
        const data = await stakingBox.getData(from);

        /*console.log({
            userAmount: web3.utils.fromWei(data.userAmount.toString(),'ether'),
            withdrawn: web3.utils.fromWei(data.withdrawn.toString(),'ether'),
            rewardsTokensPerSec: web3.utils.fromWei(data.rewardsTokensPerSec.toString(),'ether'),
            pendingRewards: web3.utils.fromWei(data.pendingRewards.toString(),'ether')
        });*/

        const tx = await stakingBox.withdraw({from: from});
        //console.log({ user: tx.logs[0].args._user, amount: web3.utils.fromWei(tx.logs[0].args._amount.toString(),'ether') });
    } catch(e) {
        console.log('CATCH', from, 'PRESTAKING BOX SIMULATION: ', new Date(now*1000).toISOString(), e.toString());
    }
}

const printUsersBalance = async (accounts) => {
    const token = await LitlabGamesToken.deployed();
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

contract("LitlabPreStakingBox tests", async(accounts) => {
    let timeCounter = Math.round((new Date().getTime() / 1000) + (2 * 30 * 24 * 3600));

    it("1. Everybody should withdraw initial 15% without penalties", async () => {
        const preStakingBox = await LitlabPreStakingBox.deployed();

        await increaseTo(timeCounter);
        for (let i=1; i<9; i++) {
            try {
                const tx = await preStakingBox.withdrawInitial({from: accounts[i]});
                console.log({ user: tx.logs[0].args._user, amount: web3.utils.fromWei(tx.logs[0].args._amount.toString(),'ether')});
            } catch(e) {
                console.log(e);
            }
        }

        await printUsersBalance(accounts);
    });

    it("2. Everybody withdraw rewards", async () => {
        const preStakingBox = await LitlabPreStakingBox.deployed();

        timeCounter = Math.round((new Date().getTime() / 1000) + (6 * 30 * 24 * 3600));
        await increaseTo(timeCounter);

        let tokensInitial = await preStakingBox.getTokensInContract();
        tokensInitial = web3.utils.fromWei(tokensInitial.toString(),'ether');

        for (let i=0; i<36; i++) {
            await withdrawRewards(accounts[1], timeCounter);
            await withdrawRewards(accounts[2], timeCounter);
            await withdrawRewards(accounts[3], timeCounter);
            await withdrawRewards(accounts[4], timeCounter);
            await withdrawRewards(accounts[5], timeCounter);
            await withdrawRewards(accounts[6], timeCounter);
            await withdrawRewards(accounts[7], timeCounter);
            await withdrawRewards(accounts[8], timeCounter);

            timeCounter += (86400 * 30);
            await increaseTo(timeCounter);
        }

        let tokensLeft = await preStakingBox.getTokensInContract();
        tokensLeft = web3.utils.fromWei(tokensLeft.toString(),'ether');

        // We sent 1.000.000 tokens for rewards. If everybody gets its rewards, the result is 999999.999999
        // We can't force a round because the rewards amount is dinamically
        const diff = tokensInitial - tokensLeft;
        assert.isAbove(diff, 999999);
        assert.isBelow(diff, 1000000);
    });

    it("3. Everybody withdraw the main investment", async () => {
        const preStakingBox = await LitlabPreStakingBox.deployed();
    
        let tokensInitial = await preStakingBox.getTokensInContract();
        tokensInitial = web3.utils.fromWei(tokensInitial.toString(),'ether');

        for (let i=0; i<3; i++) {
            console.log('PRESTAKING BOX SIMULATION: ', new Date(timeCounter*1000).toISOString());
    
            await withdraw(accounts[1], timeCounter);
            await withdraw(accounts[2], timeCounter);
            await withdraw(accounts[3], timeCounter);
            await withdraw(accounts[4], timeCounter);
            await withdraw(accounts[5], timeCounter);
            await withdraw(accounts[6], timeCounter);
            await withdraw(accounts[7], timeCounter);
            await withdraw(accounts[8], timeCounter);
   
            timeCounter += (86400 * 30);
            await increaseTo(timeCounter);
        }

        // If everybody withdraw the entire rewards plus their investment. Contract balance should be 0 (or between 0 and 0.1 because the decimal round)
        let tokensLeft = await preStakingBox.getTokensInContract();
        tokensLeft = web3.utils.fromWei(tokensLeft.toString(),'ether');
        assert.isAbove(Number(tokensLeft), 0);
        assert.isBelow(Number(tokensLeft), 0.1);

        await printUsersBalance(accounts);
    });
});