const Token = artifacts.require("EIP20/EIP20");
const Voting = artifacts.require("Voting");
const Registry = artifacts.require("Registry");

const fs = require('fs');

module.exports = function(deployer, network, accounts) {

    const config = JSON.parse(fs.readFileSync('./conf/config.json'));

    (async () => {
        deployer.deploy(
            Token, config.token.supply, config.token.name, config.token.decimals,
            config.token.symbol
        )
        const token = await Token.deployed();

        // token distribution
        var distAmount = config.token.supply / accounts.length;
        for (var i = 1; i < accounts.length; i++) { // skip owner
            await token.transfer( accounts[i], distAmount);
        }

        deployer.deploy(Voting, token.address);
        const voting = await Voting.deployed();

        deployer.deploy(Registry, token.address, voting.address);
    })();
};
