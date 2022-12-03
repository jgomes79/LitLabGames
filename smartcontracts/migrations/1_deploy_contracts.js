const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const CyberTitansGame = artifacts.require("./CyberTitansGame.sol");

async function doDeploy(deployer, network, accounts) {

    await deployer.deploy(LitlabGamesToken);
    let token = await LitlabGamesToken.deployed();
    console.log('LitlabGamesToken deployed:', token.address);   

    await deployer.deploy(CyberTitansGame, accounts[0], accounts[1], accounts[2]);
    let cyberTitansGame = await CyberTitansGame.deployed();
    console.log('CyberTitansGame deployed:', cyberTitansGame.address);
}

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
};