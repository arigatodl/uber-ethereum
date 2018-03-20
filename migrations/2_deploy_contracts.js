const Token = artifacts.require("EIP20");
const Voting = artifacts.require("Voting");
const Registry = artifacts.require("Registry");

const fs = require('fs');

module.exports = function(deployer, network, accounts) {
    const config = JSON.parse(fs.readFileSync('./conf/config.json'));
    
    async function distributeTokens() {
        const token = await Token.deployed();

        var distAmount = config.token.supply / accounts.length;
        for (var i = 1; i < accounts.length; i++) { // skip owner
            await token.transfer( accounts[i], distAmount);
        }
    }
    
    deployer.then(async () => {
        await deployer.deploy(Token, config.token.supply, config.token.name, config.token.decimals,
            config.token.symbol);
        await deployer.deploy(Voting, Token.address);
        await deployer.deploy(Registry, Token.address, Voting.address);
        
        await distributeTokens();
    })
};
