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

    uint constant MIN_AMOUNT = 20;   // prevents spamming and trolling

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

    mapping(address => DriverProfile) driverProfiles;
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

}
