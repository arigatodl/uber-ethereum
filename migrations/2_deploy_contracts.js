const Token = artifacts.require("zeppelin-solidity/contracts/token/ERC20/StandardToken.sol");
const Registry = artifacts.require("Registry");

module.exports = function(deployer) {
    deployer.deploy(Token);
    deployer.then(function()
    {
        return Token.deployed();
    })
    .then(token => {
        deployer.deploy(Registry, token);
    });
};
