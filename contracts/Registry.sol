pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

contract Registry {

    /**
     * Event emitted when a new driver applies.
     * @param sender The account that ran the action.
     * @param data The application information.
     */
    event LogNewApplication(address sender, string data);

    /**
     * Event emitted when a driver withdraws the application.
     * @param sender The account that ran the action.
     */
    event LogWithdrawApplication(address sender);

    /**
     * Event emitted when a new profile is challenged.
     * @param sender The account that ran the action.
     * @param driverAddress Address of a driver whose profile is being challenged.
     */
    event LogNewChallenge(address sender, address driverAddress);

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
    }

    struct Challenge {
        address challenger;                             // Owner of Challenge
        bool isResolved;                                // Indication of if challenge is resolved
        mapping(address => bool) voterCanClaimReward;   // Indicates whether a voter has claimed a reward yet
    }

    mapping(address => DriverProfile) public driverProfiles;
    mapping(address => Challenge) public challenges;
    StandardToken public token;

    /**
     * Constructor
     * @param tokenAddress ERC20 token address.
     */
    function Registry(address tokenAddress)
        public
    {
        token = StandardToken(tokenAddress);
    }

    // --------------------
    // PUBLISHER INTERFACE:
    // --------------------

    /**
     * Called by a new driver.
     * Takes staking token and creates the profile.
     * @param amount The number of ERC20 tokens a driver is willing to stake.
     * @param data Information of a driver.
     * @return Whether the action was successful.
     * Emits LogNewApplication.
     */
    function apply(uint amount, string data)
        public
    {
        require(!driverExists(msg.sender)); // is a new driver
        require(amount >= MIN_AMOUNT);

        require(token.transferFrom(msg.sender, this, amount));

        driverProfiles[msg.sender].status = ProfileStatus.NEW;
        driverProfiles[msg.sender].stakedAmount = amount;

        LogNewApplication(msg.sender, data);
    }

    /**
     * Called by an owner of the application.
     * Returns staked amount to a caller and deletes the profile.
     * @return Whether the action was successful.
     * Emits LogWithdrawApplication.
     */
    function withdraw()
        public
        returns (bool)
    {
        require(driverExists(msg.sender));      // already exists
        require(isWithdrawable(msg.sender));    // application can be withdrawn

        // transfer staked amount
        if (driverProfiles[msg.sender].stakedAmount > 0)
            require(token.transfer(msg.sender, driverProfiles[msg.sender].stakedAmount));

        delete driverProfiles[msg.sender];

        LogWithdrawApplication(msg.sender);
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
    function challenge(address driverAddress)
        public
    {
        require(isChallengable(driverAddress)); // can be challenged

        // Takes tokens from challenger
        require(token.transferFrom(msg.sender, this, MIN_AMOUNT));

        challenges[driverAddress].challenger = msg.sender;
        challenges[driverAddress].isResolved = false;
        driverProfiles[msg.sender].status = ProfileStatus.IN_CHALLENGE;

        LogNewChallenge(msg.sender, driverAddress);
    }

    function driverExists(address driverAddress)
        constant
        public
        returns (bool)
    {
        return (driverProfiles[driverAddress].status != ProfileStatus.NOT_EXISTS);
    }

    function isWithdrawable(address driverAddress)
        constant
        public
        returns (bool)
    {
        return (driverProfiles[driverAddress].status == ProfileStatus.NEW);
    }

    function isChallengable(address driverAddress)
        constant
        public
        returns (bool)
    {
        return (driverProfiles[driverAddress].status == ProfileStatus.NEW);
    }

}
