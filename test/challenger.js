const Eth = require('ethjs');
const BN = require('bignumber.js');

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
        minStakeAmount = 20;
    });

    describe('Function: challenge and resolveChallenge', () => {

        it('should successfully challenge an existing application', async () => {
            const challengerStartingBalance = await token.balanceOf.call(challenger0);

            // new driver applies
            await token.approve(registry.address, minStakeAmount, { from: driver0 });
            await registry.apply(minStakeAmount, "s", { from: driver0 });

            // challenges
            await token.approve(registry.address, minStakeAmount, { from: challenger0 });
            let txnChallenge = await registry.challenge(driver0, { from: challenger0 });

            const challengerFinalBalance = await token.balanceOf.call(challenger0);

            assert.strictEqual(
                txnChallenge.logs[0].args.pollId.toNumber(), 1,
                'challenge id is not increasing correctly'
            );

            const expectedFinalBalance = challengerStartingBalance.minus(new BN(minStakeAmount, 10));
            assert.strictEqual(
                expectedFinalBalance.toString(10), challengerFinalBalance.toString(10),
                'challenger staking is not deducting correctly'
            );

            await token.approve(voting.address, 420, { from: voter0 });
            let txnCommitVote = await voting.commitVote(1, 10, 420, { from: voter0} );

            await token.approve(voting.address, 420, { from: voter1 });
            txnCommitVote = await voting.commitVote(1, 10, 420, { from: voter1} );

            await token.approve(voting.address, 420, { from: voter1 });
            txnCommitVote = await voting.commitVote(1, 10, 420, { from: voter1} );

            let txnResolveChallenge = await registry.resolveChallenge(1, { from: challenger0 });

            //await registry.apply(minStakeAmount, "s", { from: driver0 });
        });

    });
});
