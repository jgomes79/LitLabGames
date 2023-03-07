const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const CyberTitansTournament = artifacts.require("./CyberTitansTournament.sol");

contract("CyberTitansTournament tests", async(accounts) => {
    let tournamentId = 0;
    const manager = accounts[0];

    it("1. Create a new tournament", async () => {
        const token = await LitlabGamesToken.deployed();
        const cyberTitansTournament = await CyberTitansTournament.deployed();

        // Approve game for 9 users
        const maxAmount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
        for (let i=1; i<10; i++) {
            await token.transfer(accounts[i], web3.utils.toWei('1000000'));
            await token.approve(cyberTitansTournament.address, maxAmount, {from: accounts[i]});
        }

        const startDate = Math.round(new Date('2023-01-01T00:00:00').getTime() / 1000);
        const txCreate = await cyberTitansTournament.createTournament(token.address, startDate, web3.utils.toWei('1000'));
        tournamentId = txCreate.logs[0].args._tournamentId;
        assert.equal(tournamentId, 1);

        await cyberTitansTournament.joinTournament(tournamentId, accounts[1], false, {from: manager});
        await cyberTitansTournament.joinTournament(tournamentId, accounts[2], false, {from: manager});
        await cyberTitansTournament.joinTournament(tournamentId, accounts[3], false, {from: manager});
        await cyberTitansTournament.joinTournament(tournamentId, accounts[4], false, {from: manager});
        await cyberTitansTournament.joinTournament(tournamentId, accounts[5], false, {from: manager});
        await cyberTitansTournament.joinTournament(tournamentId, accounts[6], false, {from: manager});
        await cyberTitansTournament.joinTournament(tournamentId, accounts[7], false, {from: manager});
        await cyberTitansTournament.joinTournament(tournamentId, accounts[8], false, {from: manager});
        await cyberTitansTournament.joinTournament(tournamentId, accounts[9], false, {from: manager});

        const balance = await token.balanceOf(cyberTitansTournament.address);
        assert.equal(balance, web3.utils.toWei('9000'));
    });

    it("2. Tournament starts", async () => {
        const cyberTitansTournament = await CyberTitansTournament.deployed();

        await cyberTitansTournament.startTournament(tournamentId, 9, 4, {from: manager});
    });

    it("3. Finalize a tournament", async () => {
        const token = await LitlabGamesToken.deployed();
        const cyberTitansTournament = await CyberTitansTournament.deployed();

        const preBalance1 = await token.balanceOf(accounts[4]);
        const preBalance2 = await token.balanceOf(accounts[8]);
        const preBalance3 = await token.balanceOf(accounts[3]);
        const preBalance4 = await token.balanceOf(accounts[7]);

        await cyberTitansTournament.finalizeTournament(tournamentId, [accounts[4], accounts[8], accounts[3], accounts[7]]);

        const postBalance1 = await token.balanceOf(accounts[4]);
        const postBalance2 = await token.balanceOf(accounts[8]);
        const postBalance3 = await token.balanceOf(accounts[3]);
        const postBalance4 = await token.balanceOf(accounts[7]);

        const diff1 = web3.utils.fromWei(postBalance1.toString(),'ether') - web3.utils.fromWei(preBalance1.toString(),'ether');
        const diff2 = web3.utils.fromWei(postBalance2.toString(),'ether') - web3.utils.fromWei(preBalance2.toString(),'ether');
        const diff3 = web3.utils.fromWei(postBalance3.toString(),'ether') - web3.utils.fromWei(preBalance3.toString(),'ether');
        const diff4 = web3.utils.fromWei(postBalance4.toString(),'ether') - web3.utils.fromWei(preBalance4.toString(),'ether');

        const pot = 9000 - (9000 * 5 / 100);
        assert.equal(diff1, pot * 40/100);
        assert.equal(diff2, pot * 27/100);
        assert.equal(diff3, pot * 19/100);
        assert.equal(diff4, pot * 14/100);
    });
});