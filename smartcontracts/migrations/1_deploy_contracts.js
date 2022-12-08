const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const LITTVestingContract = artifacts.require("./LITTVestingContract.sol");
const CyberTitansGame = artifacts.require("./CyberTitansGame.sol");

async function doDeploy(deployer, network, accounts) {
    const litGamesWallet = accounts[0];

    await deployer.deploy(LitlabGamesToken);
    let token = await LitlabGamesToken.deployed();
    console.log('LitlabGamesToken deployed:', token.address);

    await deployer.deploy(LITTVestingContract, litGamesWallet);
    let vesting = await LITTVestingContract.deployed();
    console.log('LITTVestingContract deployed:', vesting.address);

    // Send all tokens to the vesting contract
    const tokenSupply = await token.totalSupply();
    await token.transfer(vesting.address, tokenSupply);

    await deployer.deploy(CyberTitansGame, accounts[0], accounts[1], accounts[2]);
    let cyberTitansGame = await CyberTitansGame.deployed();
    console.log('CyberTitansGame deployed:', cyberTitansGame.address);
}

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
};