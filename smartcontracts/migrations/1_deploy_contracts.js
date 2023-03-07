const LitlabForwarder = artifacts.require("./LitlabForwarder.sol");
const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const LitlabPreStakingBox = artifacts.require("./LitlabPreStakingBox.sol");
const LITTVestingContract = artifacts.require("./LITTVestingContract.sol");
const LITTAdvisorsTeam = artifacts.require("./LITTAdvisorsTeam.sol");
const CyberTitansGame = artifacts.require("./CyberTitansGame.sol");
const CyberTitansTournament = artifacts.require("./CyberTitansTournament.sol");

async function doDeploy(deployer, network, accounts) {
    const litGamesWallet = accounts[0];
    const stakingStart = Math.round(new Date('2023-01-01T00:00:00').getTime() / 1000);
    const stakingEnd = Math.round(new Date('2026-01-01T00:00:00').getTime() / 1000);
    const totalRewards = web3.utils.toWei('1000000');
    const stakersAmount = web3.utils.toWei('1800000');
    const vestingAmount = web3.utils.toWei('1825000000');
    const advisorsAndTeamAmount = web3.utils.toWei('540000000');

    const wallets = [accounts[1], accounts[2], accounts[3], accounts[4], accounts[5], accounts[6], accounts[7], accounts[8]];
    const amounts = [web3.utils.toWei('400000'), web3.utils.toWei('350000'), web3.utils.toWei('300000'), web3.utils.toWei('250000'), web3.utils.toWei('200000'), web3.utils.toWei('150000'), web3.utils.toWei('100000'), web3.utils.toWei('50000')];
    const investorTypes = [0,0,1,1,2,2,2,2];
    const teamApprovalWallets = [accounts[1], accounts[2], accounts[3], accounts[4], accounts[5]];
    const teamWallet = accounts[9];
    const antisnipeAddress = web3.utils.toChecksumAddress("0x0000000000000000000000000000000000000000");

    await deployer.deploy(LitlabGamesToken, antisnipeAddress);
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

    await token.transfer(vesting.address, vestingAmount);
    console.log(`Sended ${web3.utils.fromWei(vestingAmount,'ether')} to the Vesting`);

    await deployer.deploy(LITTAdvisorsTeam, token.address, teamWallet, teamApprovalWallets);
    let advisorsTeam = await LITTAdvisorsTeam.deployed();
    console.log('LITTAdvisorsTeam deployed:', advisorsTeam.address);

    await token.transfer(advisorsTeam.address, advisorsAndTeamAmount);
    console.log(`Sended ${web3.utils.fromWei(advisorsAndTeamAmount,'ether')} to the AdvisorsTeam contract`);

    await deployer.deploy(LitlabForwarder);
    let forwarder = await LitlabForwarder.deployed();
    console.log('LitlabForwarder deployed:', forwarder.address);

    await deployer.deploy(CyberTitansGame, forwarder.address, accounts[0], accounts[0], token.address, web3.utils.toWei('100000000'));
    let cyberTitansGame = await CyberTitansGame.deployed();
    console.log('CyberTitansGame deployed:', cyberTitansGame.address);

    await deployer.deploy(CyberTitansTournament, forwarder.address, accounts[0], accounts[0], token.address);
    let cyberTitansTournament = await CyberTitansTournament.deployed();
    console.log('CyberTitansTournament deployed:', cyberTitansTournament.address);
}

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
};