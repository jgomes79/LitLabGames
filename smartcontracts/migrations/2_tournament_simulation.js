const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const CyberTitansTournament = artifacts.require("./CyberTitansTournament.sol");

async function doDeploy(deployer, network, accounts) {
    const manager = accounts[0];
    const token = await LitlabGamesToken.deployed();
    console.log('LitlabGamesToken deployed:', token.address);

    const cyberTitansTournament = await CyberTitansTournament.deployed();
    console.log('CyberTitansTournament deployed:', cyberTitansTournament.address);

    const maxAmount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
    for (let i=1; i<=9; i++) {
        await token.transfer(accounts[i], web3.utils.toWei('1000000'));
        await token.approve(cyberTitansTournament.address, maxAmount, {from: accounts[i]});
    }

    const startDate = Math.round(new Date('2023-01-01T00:00:00').getTime() / 1000);
    const tx = await cyberTitansTournament.createTournament(token.address, startDate, web3.utils.toWei('1000'));
    const tournamentId = tx.logs[0].args._tournamentId;

    await cyberTitansTournament.joinTournament(tournamentId, accounts[1], false, {from: manager});
    await cyberTitansTournament.joinTournament(tournamentId, accounts[2], false, {from: manager});
    await cyberTitansTournament.joinTournament(tournamentId, accounts[3], false, {from: manager});
    await cyberTitansTournament.joinTournament(tournamentId, accounts[4], false, {from: manager});
    await cyberTitansTournament.joinTournament(tournamentId, accounts[5], false, {from: manager});
    await cyberTitansTournament.joinTournament(tournamentId, accounts[6], false, {from: manager});
    await cyberTitansTournament.joinTournament(tournamentId, accounts[7], false, {from: manager});
    await cyberTitansTournament.joinTournament(tournamentId, accounts[8], false, {from: manager});
    await cyberTitansTournament.joinTournament(tournamentId, accounts[9], false, {from: manager});

    let balance = await token.balanceOf(cyberTitansTournament.address);
    console.log('Balance: ', balance.toString());

    const tx2 = await cyberTitansTournament.finalizeTournament(tournamentId, [accounts[4], accounts[8], accounts[1], accounts[5]]);
    console.log(tx2.logs[0].args);

    balance = await token.balanceOf(cyberTitansTournament.address);
    console.log('Balance: ', balance.toString());
}

module.exports = function(deployer, network, accounts) {
    deployer.then(async () => {
        await doDeploy(deployer, network, accounts);
    });
};