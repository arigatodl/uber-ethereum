const Token = artifacts.require("EIP20");
const Voting = artifacts.require("Voting");
const Registry = artifacts.require("Registry");

const fs = require('fs');

module.exports = function(deployer, network, accounts) {
    let token;
    const config = JSON.parse(fs.readFileSync('./conf/config.json'));

    async function distributeTokens() {
        const _token = await Token.deployed();

        var distAmount = config.token.supply / accounts.length;
        for (var i = 1; i < accounts.length; i++) { // skip owner
            await token.transfer( accounts[i], distAmount);
        }
    }

    deployer.deploy(
        Token, config.token.supply, config.token.name, config.token.decimals,
        config.token.symbol
    )
    .then(function() {
        return Token.deployed();
    })
    .then(_token => {
        token = _token;

        deployer.deploy(Voting, token.address);
    })
    .then(function() {
        return Voting.deployed();
    })
    .then(_voting => {
        deployer.deploy(Registry, token.address, _voting.address);
    })
    .then(async () => distributeTokens())

};
