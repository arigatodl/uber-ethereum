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

        it('should successfully challenge an existing application', async () => {
            const challengerStartingBalance = await token.balanceOf.call(challenger0);
            /*
            // new driver applies
            await token.approve(registry.address, minStakeAmount, { from: driver0 });
            await registry.apply(minStakeAmount, "s", { from: driver0 });
            
            // challenges
            await token.approve(registry.address, minStakeAmount, { from: challenger0 });
            const challengeId = await registry.challenge(driver0, { from: challenger0 });
            
            const challengerFinalBalance = await token.balanceOf(challenger0);*/
            
            /*assert.strictEqual(
                challengeId.toString(10), "1",
                'challenge id is not increasing correctly'
            );*/
            
            //const expectedFinalBalance = challengerStartingBalance.add(new BN(minStakeAmount, 10));
            /*assert.strictEqual(
                expectedFinalBalance.toString(10), challengerFinalBalance.toString(10),
                'challenger staking is not deducting correctly'
            );*/
        });

        it('should not allow an existing driver to apply', async () => {
            await token.approve(registry.address, 200, { from: driver0 });
            await registry.apply(200, "s", { from: driver0 });
            await registry.exit({ from: driver0 });
        });

    });

    describe('Function: resolveChallenge', () => {

        it('should allow a new driver to apply', async () => {
            await token.approve(registry.address, 200, { from: driver0 });
            await registry.apply(200, "s", { from: driver0 });
            await registry.exit({ from: driver0 });
        });

        it('should not allow an existing driver to apply', async () => {
            await token.approve(registry.address, 200, { from: driver0 });
            await registry.apply(200, "s", { from: driver0 });
            await registry.exit({ from: driver0 });
        });

    });
});
