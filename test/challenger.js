const Eth = require('ethjs');

const Token = artifacts.require('EIP20.sol');
const Voting = artifacts.require('Voting.sol');
const Registry = artifacts.require('Registry.sol');

contract('Registry', (accounts) => {
    let minStakeAmount;
    let registry;
    let token;
    let voting;
    const owner = accounts[0];
    const driver0 = accounts[1];
    const driver1 = accounts[2];
    const challenger0 = accounts[3];
    const challenger1 = accounts[4];
    const voter0 = accounts[5];
    const voter1 = accounts[6];
    const voter2 = accounts[7];

    before("should prepare", async () => {
        registry = await Registry.deployed();
        token = await Token.deployed();
        voting = await Voting.deployed();
        minStakeAmount = registry.MIN_AMOUNT;
    });

    describe('Function: challenge', () => {

        it('should allow a new driver to apply', async () => {
            await token.approve(registry.address, 200, { from: driver0 });
            await registry.apply(200, "s", { from: driver0 });

            /*
            // get the struct in the mapping
            const result = await registry.listings.call(listing);
            // check that Application is initialized correctly
            assert.strictEqual(result[0].gt(0), true, 'challenge time < now');
            assert.strictEqual(result[1], false, 'whitelisted != false');
            assert.strictEqual(result[2], applicant, 'owner of application != address that applied');
            assert.strictEqual(
            result[3].toString(10),
            paramConfig.minDeposit.toString(10),
            'incorrect unstakedDeposit',
        );*/
        });

        it('should not allow an existing driver to apply', async () => {
            await token.approve(registry.address, 200, { from: driver0 });
            await registry.apply(200, "s", { from: driver0 });
        });

    });

    describe('Function: resolveChallenge', () => {

        it('should allow a new driver to apply', async () => {
            await token.approve(registry.address, 200, { from: driver0 });
            await registry.apply(200, "s", { from: driver0 });

            /*
            // get the struct in the mapping
            const result = await registry.listings.call(listing);
            // check that Application is initialized correctly
            assert.strictEqual(result[0].gt(0), true, 'challenge time < now');
            assert.strictEqual(result[1], false, 'whitelisted != false');
            assert.strictEqual(result[2], applicant, 'owner of application != address that applied');
            assert.strictEqual(
            result[3].toString(10),
            paramConfig.minDeposit.toString(10),
            'incorrect unstakedDeposit',
        );*/
        });

        it('should not allow an existing driver to apply', async () => {
            await token.approve(registry.address, 200, { from: driver0 });
            await registry.apply(200, "s", { from: driver0 });
        });

    });
});
