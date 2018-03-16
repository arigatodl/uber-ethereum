const Registry = artifacts.require("Registry");

module.exports = function(deployer) {
	deployer.deploy(Registry, '0x06E58BD5DeEC63129a79c9cD3A653655EdBef820');
};
