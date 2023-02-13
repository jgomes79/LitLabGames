const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const LitlabPreStakingBox = artifacts.require("./LitlabPreStakingBox.sol");
const LITTVestingContract = artifacts.require("./LITTVestingContract.sol");
const LITTAdvisorsTeam = artifacts.require("./LITTAdvisorsTeam.sol");
const CyberTitansGame = artifacts.require("./CyberTitansGame.sol");

async function doDeploy(deployer, network, accounts) {
    const litGamesWallet = accounts[0];
    const stakingStart = Math.round(new Date('2023-01-01T00:00:00').getTime() / 1000);
    const stakingEnd = Math.round(new Date('2026-01-01T00:00:00').getTime() / 1000);
    const totalRewards = web3.utils.toWei('1000000');
    const stakersAmount = web3.utils.toWei('1800000');

    const wallets = [accounts[1], accounts[2], accounts[3], accounts[4], accounts[5], accounts[6], accounts[7], accounts[8]];
    const amounts = [web3.utils.toWei('400000'), web3.utils.toWei('350000'), web3.utils.toWei('300000'), web3.utils.toWei('250000'), web3.utils.toWei('200000'), web3.utils.toWei('150000'), web3.utils.toWei('100000'), web3.utils.toWei('50000')];
    const investorTypes = [0,0,1,1,2,2,2,2];
    const teamApprovalWallets = [accounts[1], accounts[2], accounts[3], accounts[4], accounts[5]];
    const teamWallet = accounts[9];

    await deployer.deploy(LitlabGamesToken);
    let token = await LitlabGamesToken.deployed();
    console.log('LitlabGamesToken deployed:', token.address);

    await deployer.deploy(LitlabPreStakingBox, token.address, stakingStart, stakingEnd, totalRewards);
    let preStakingBox = await LitlabPreStakingBox.deployed();
    console.log('LitlabPreStakingBox deployed:', preStakingBox.address);

    await token.transfer(preStakingBox.address, totalRewards);
    console.log(`Sended ${web3.utils.fromWei(totalRewards,'ether')} to the PreStakingBox as TotalRewards`);

    await preStakingBox.stake(wallets, amounts, investorTypes);
    console.log('Stakers added to the PreStakingBox');

    await token.transfer(preStakingBox.address, stakersAmount);
    console.log(`Sended ${web3.utils.fromWei(stakersAmount,'ether')} to the PreStakingBox as StakersBalance`);

    await deployer.deploy(LITTVestingContract, token.address, litGamesWallet);
    let vesting = await LITTVestingContract.deployed();
    console.log('LITTVestingContract deployed:', vesting.address);

    await deployer.deploy(LITTAdvisorsTeam, token.address, teamWallet, teamApprovalWallets);
    let advisorsTeam = await LITTAdvisorsTeam.deployed();
    console.log('LITTAdvisorsTeam deployed:', advisorsTeam.address);

    // Send all tokens to the vesting contract
    //const tokenSupply = await token.totalSupply();
    //await token.transfer(vesting.address, tokenSupply);

    await deployer.deploy(CyberTitansGame, accounts[0], accounts[2], token.address);
    let cyberTitansGame = await CyberTitansGame.deployed();
    console.log('CyberTitansGame deployed:', cyberTitansGame.address);
}

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
};