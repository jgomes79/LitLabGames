const LitlabGamesToken = artifacts.require("./LitlabGamesToken.sol");
const CyberTitansGame = artifacts.require("./CyberTitansGame.sol");

contract("CyberTitansGame tests", async(accounts) => {
    let gameId = 0;

    it("1. Create a new game", async () => {
        const token = await LitlabGamesToken.deployed();
        const cyberTitansGame = await CyberTitansGame.deployed();

        await cyberTitansGame.updateWaitMinutes(0); // To remove the waiting time between create and finalize a game (only for testing)

        // Approve game for 8 users
        const maxAmount = '115792089237316195423570985008687907853269984665640564039457584007913129639935'; //(2^256 - 1 )
        for (let i=1; i<9; i++) {
            await token.transfer(accounts[i], web3.utils.toWei('1000000'));
            await token.approve(cyberTitansGame.address, maxAmount, {from: accounts[i]});
        }

        // To check in a single transaction if all wallets have approved and have enough tokens to spend in the game
        const players = [accounts[1], accounts[2], accounts[3], accounts[4], accounts[5], accounts[6], accounts[7], accounts[8]];
        await cyberTitansGame.checkWallets(players, web3.utils.toWei('10000000'), token.address);

        // Create the game (100 litlabgames tokens cost per 8 players) and get the id 
        const tx = await cyberTitansGame.createGame(players, token.address, web3.utils.toWei('100'));

        gameId = tx.logs[0].args._gameId;
        assert.equal(gameId, 1);

        const balance = await token.balanceOf(cyberTitansGame.address);
        assert.equal(balance, web3.utils.toWei('800'));
    });

    it("2. Finalize a game", async () => {
        const token = await LitlabGamesToken.deployed();
        const cyberTitansGame = await CyberTitansGame.deployed();

        const preBalance1 = await token.balanceOf(accounts[4]);
        const preBalance2 = await token.balanceOf(accounts[8]);
        const preBalance3 = await token.balanceOf(accounts[3]);

        await cyberTitansGame.finalizeGame(gameId, [accounts[4], accounts[8], accounts[3]]);

        const postBalance1 = await token.balanceOf(accounts[4]);
        const postBalance2 = await token.balanceOf(accounts[8]);
        const postBalance3 = await token.balanceOf(accounts[3]);

        assert.equal(Math.round(web3.utils.fromWei((postBalance1 - preBalance1).toString(), 'ether')), 800*47.5/100);
        assert.equal(Math.round(web3.utils.fromWei((postBalance2 - preBalance2).toString(), 'ether')), 800*28.5/100);
        assert.equal(Math.round(web3.utils.fromWei((postBalance3 - preBalance3).toString(), 'ether')), 800*19.0/100);
    });
});