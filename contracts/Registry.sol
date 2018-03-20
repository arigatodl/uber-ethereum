pragma solidity ^0.4.18;

import "./EIP20.sol";
import "./Voting.sol";

contract Registry {

    event LogNewApplication(address sender, uint amount, string data);
    event LogExit(address sender);
    event LogNewChallenge(address sender, address driverAddr, uint pollId);
    event LogChallengeResolved(address driverAddr, bool isAccepted);


    uint constant public MIN_AMOUNT = 20;   // prevents spamming and trolling

    enum ProfileStatus {
        NOT_EXISTS,     // doesn't exist
        NEW,            // applied and not-yet challenged
        IN_CHALLENGE,   // currently being challenged
        ACCEPTED        // accepted to the registry
    }

    struct DriverProfile {
        uint stakedAmount;
        ProfileStatus status;
        string data;
    }

    struct Challenge {
        address challenger;                             // Owner of Challenge
        address driverAddr;                             // driver address
        bool isResolved;                                // Indication of if challenge is resolved
        mapping(address => bool) voterCanClaimReward;   // Indicates whether a voter has claimed a reward yet
    }

    mapping(address => DriverProfile) private driverProfiles;
    mapping(uint => Challenge) public challenges;
    EIP20 public token;
    Voting public voting;

    /**
     * Constructor
     * @param tokenAddr ERC20 token address.
     */
    function Registry(address tokenAddr, address votingAddr)
        public
    {
        token = EIP20(tokenAddr);
        voting = Voting(votingAddr);
    }

    // --------------------
    // DRIVER INTERFACE:
    // --------------------

    /**
     * Called by a new driver.
     * Takes staking token and driver information then creates the profile.
     * @param amount The number of ERC20 tokens a driver is willing to stake.
     * @param data Information of a driver.
     * Emits LogNewApplication.
     */
    function apply(uint amount, string data)
        public
        returns (bool)
    {
        require(!driverExists(msg.sender)); // is a new driver
        require(amount >= MIN_AMOUNT);

        require(token.transferFrom(msg.sender, this, amount));

        driverProfiles[msg.sender].status = ProfileStatus.NEW;
        driverProfiles[msg.sender].stakedAmount = amount;
        driverProfiles[msg.sender].data = data;

        LogNewApplication(msg.sender, amount, data);
        return true;
    }

    /**
     * Called by an owner of the application.
     * Returns staked amount to a caller and deletes the profile.
     * @return Whether the action was successful.
     * Emits LogExit.
     */
    function exit()
        public
        returns (bool)
    {
        require(driverExists(msg.sender));  // already exists
        require(isExitable(msg.sender));    // can be removed

        // transfer staked amount
        if (driverProfiles[msg.sender].stakedAmount > 0)
            require(token.transfer(msg.sender, driverProfiles[msg.sender].stakedAmount));

        delete driverProfiles[msg.sender];

        LogExit(msg.sender);
        return true;
    }

    // --------------------
    // TOKEN HOLDER INTERFACE:
    // --------------------

    /**
     * Called by a token holder.
     * Returns staked amount to a caller and deletes the profile.
     * @return Whether the action was successful.
     * Emits LogNewChallenge.
     */
    function challenge(address driverAddr)
        public
        returns (uint)
    {
        require(isChallengable(driverAddr)); // can be challenged

        // Takes tokens from challenger
        require(token.transferFrom(msg.sender, this, MIN_AMOUNT));

        uint pollId = voting.startPoll(
            uint(70),
            100,
            50
        );

        challenges[pollId].challenger = msg.sender;
        challenges[pollId].driverAddr = driverAddr;
        challenges[pollId].isResolved = false;
        driverProfiles[driverAddr].status = ProfileStatus.IN_CHALLENGE;

        LogNewChallenge(msg.sender, driverAddr, pollId);
        return pollId;
    }

    function resolveChallenge(uint challengeId)
        public
    {
        require(challenges[challengeId].isResolved == false); // is not resolved yet
        require(voting.isPollFinished(challengeId)); // poll must be finished

        address driverAddr = challenges[challengeId].driverAddr;
        challenges[challengeId].isResolved = true;

        if (voting.isAccepted(challengeId)) {    // challenger has failed
            driverProfiles[driverAddr].status = ProfileStatus.ACCEPTED;

        } else {
            address challengerAddr = challenges[challengeId].challenger;

            // send winning reward
            require(token.transfer(challengerAddr, driverProfiles[driverAddr].stakedAmount));
            delete driverProfiles[driverAddr];
        }

        LogChallengeResolved(driverAddr, voting.isAccepted(challengeId));
    }

    function driverExists(address driverAddr)
        constant
        public
        returns (bool)
    {
        return (driverProfiles[driverAddr].status != ProfileStatus.NOT_EXISTS);
    }

    function isExitable(address driverAddr)
        constant
        public
        returns (bool)
    {
        return (driverExists(driverAddr) && driverProfiles[driverAddr].status != ProfileStatus.IN_CHALLENGE);
    }

    function isChallengable(address driverAddr)
        constant
        public
        returns (bool)
    {
        return (driverProfiles[driverAddr].status == ProfileStatus.NEW);
    }

    function duringChallenge(address driverAddr)
        constant
        public
        returns (bool)
    {
        return (driverProfiles[driverAddr].status == ProfileStatus.IN_CHALLENGE);
    }

    function isAccepted(address driverAddr)
        constant
        public
        returns (bool)
    {
        return (driverProfiles[driverAddr].status == ProfileStatus.ACCEPTED);
    }

}
