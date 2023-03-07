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
        const data = await stakingBox.getData(from);
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

        const tx = await stakingBox.withdraw({from: from});
        // console.log({ user: tx.logs[0].args._user, amount: web3.utils.fromWei(tx.logs[0].args._amount.toString(),'ether') });
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

    it("1. Everybody should withdraw initial 15% without penalties", async () => {
        const preStakingBox = await LitlabPreStakingBox.deployed();

        await printUsersBalance(accounts);

        let oneMonthLater = Math.round((new Date().getTime() / 1000) + (1 *30 * 24 * 3600));
        await increaseTo(oneMonthLater);
        for (let i=1; i<9; i++) {
            const tx = await preStakingBox.withdrawInitial({from: accounts[i]});
            console.log({ user: tx.logs[0].args._user, amount: web3.utils.fromWei(tx.logs[0].args._amount.toString(),'ether')});
        }

        await printUsersBalance(accounts);
    });

    it("2. Everybody withdraw rewards but user 7 that get everything", async () => {
        let oneMonthLater = Math.round((new Date().getTime() / 1000) + (6 *30 * 24 * 3600));

        await increaseTo(oneMonthLater);

        await withdrawRewards(accounts[1], oneMonthLater);
        await withdrawRewards(accounts[2], oneMonthLater);
        await withdrawRewards(accounts[3], oneMonthLater);
        await withdrawRewards(accounts[4], oneMonthLater);
        await withdrawRewards(accounts[5], oneMonthLater);
        await withdrawRewards(accounts[6], oneMonthLater);
        await withdrawRewards(accounts[7], oneMonthLater);
        await withdrawRewards(accounts[8], oneMonthLater);

        await printUsersBalance(accounts);
    });

    it("3. Should simulate the vesting a tournament", async () => {
        const token = await LitlabGamesToken.deployed();
        const preStakingBox = await LitlabPreStakingBox.deployed();
        let startTime = Math.round((new Date().getTime() / 1000) + (12 * 30 * 24 * 3600));
    
        for (let i=0; i<365*2; i++) {
            await increaseTo(startTime);
            console.log('PRESTAKING BOX SIMULATION: ', new Date(startTime*1000).toISOString());
    
            await withdrawRewards(accounts[1], startTime);
            await withdrawRewards(accounts[2], startTime);
            await withdrawRewards(accounts[3], startTime);
            await withdrawRewards(accounts[4], startTime);
            await withdrawRewards(accounts[5], startTime);
            await withdrawRewards(accounts[6], startTime);
            await withdrawRewards(accounts[7], startTime);
            await withdrawRewards(accounts[8], startTime);
    
            let tokensLeft = await preStakingBox.getTokensInContract();
            console.log('TOKENS LEFT IN CONTRACT: ', web3.utils.fromWei(tokensLeft.toString(),'ether'));   
    
            startTime += (86400 * 30);
    
            await printUsersBalance(accounts);
        }
    });
});