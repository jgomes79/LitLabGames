const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const CyberTitansGame = artifacts.require("./CyberTitansGame.sol");

async function doDeploy(deployer, network, accounts) {

    let token = await LitlabGamesToken.deployed();
    console.log('LitlabGamesToken deployed:', token.address);

    let cyberTitansGame = await CyberTitansGame.deployed();
    console.log('CyberTitansGame deployed:', cyberTitansGame.address);

    const maxAmount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
    for (let i=1; i<9; i++) {
        await token.transfer(accounts[i], web3.utils.toWei('1000000'));
        await token.approve(cyberTitansGame.address, maxAmount, {from: accounts[i]});
    }

    const poolWallet = await cyberTitansGame.poolWallet();
    await token.transfer(poolWallet, web3.utils.toWei('10000000'));
    await token.approve(cyberTitansGame.address, maxAmount, {from: poolWallet});

    const players = [accounts[1], accounts[2], accounts[3], accounts[4], accounts[5], accounts[6], accounts[7], accounts[8]];
    const ctt = [false, false, false, false, false, false, true, true];
    const tx = await cyberTitansGame.createGame(players, ctt, token.address, 3);
    console.log(tx);
    console.log(tx.logs[0]);
    const gameId = tx.logs[0].args._gameId;

    const tx2 = await cyberTitansGame.finalizeGame(gameId, accounts[4], accounts[8], accounts[2]);
    console.log(tx2);
}

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
};