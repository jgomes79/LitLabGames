const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const CyberTitansGame = artifacts.require("./CyberTitansGame.sol");
const CyberTitansTournament = artifacts.require("./CyberTitansTournament.sol");

async function doDeploy(deployer, network, accounts) {
    const account = accounts[3];
    const payerAccount = accounts[0];
    
    let token = await LitlabGamesToken.deployed();
    console.log('LitlabGamesToken deployed:', token.address);

    let cyberTitansGame = await CyberTitansGame.deployed();
    console.log('CyberTitansGame deployed:', cyberTitansGame.address);

    let cyberTitansTournament = await CyberTitansTournament.deployed();
    console.log('CyberTitansTournament deployed:', cyberTitansTournament.address);

    await token.transfer(account, web3.utils.toWei('1000000'));

    try {
        const tx = await cyberTitansGame.createGame([accounts[3]], token.address, web3.utils.toWei('1000'));
        console.log(tx);
    } catch(e) {
        console.error(e);
    }
    
    try {
        const r = "0xf38259080d27622892577cb1578d0829d3b6fcc990767456f3d571aae0054d90";
        const s = "0x092327fe889d5aa24289f071177a36fd46fc72374556a1b9e4e2305beeb68b00";
        const v = 28;

        const x = await erc20Token.methods.permit(account, gameAddress, web3.utils.toWei('1000000000'), nonce, 2661766724, v, r, s);

        const tx = await cyberTitansGame.createGame([accounts[3]], token.address, web3.utils.toWei('1000'));
        console.log(tx);
    } catch(e) {
        console.error(e);
    }

}

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
};