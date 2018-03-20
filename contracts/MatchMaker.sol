pragma solidity ^0.4.18;

import "./Registry.sol";
import "./EIP20.sol";

contract MatchMaker {

    event LogListingAdded(address sender, uint id, uint farePerKM, string locaiton);
    event LogTripStarted(address passenger, address driver, uint payment,
        string destination, uint kilometers);
    event LogTripCompleted(address passenger, address driver, uint payment,
        uint kilometers);

    struct Driver {
        uint farePerKM;
        string location;
        uint lockedAmount;
        address driverAddr;
        address passengerAddr;
    }

    mapping(uint => Driver) public listings;

    uint public listingsCnt;
    Registry public registry;
    EIP20 public token;

    function MatchMaker(address registryAddr, address tokenAddr) public {
        registry = Registry(registryAddr);
        token = EIP20(tokenAddr);
        listingsCnt = 0;
    }

    function addListing(uint farePerKM, string location)
        public
        returns (uint)
    {
        require(registry.isAccepted(msg.sender));   // driver is accepted

        listingsCnt = listingsCnt + 1;
        listings[listingsCnt] = Driver({
                farePerKM: farePerKM,
                location: location,
                lockedAmount: 0,
                driverAddr: msg.sender,
                passengerAddr: address(0)
            });

        LogListingAdded(msg.sender, listingsCnt, farePerKM, location);
        return listingsCnt;
    }

    function startTrip(uint id, uint KM, string destination)
        public
        returns (bool)
    {
        require(listingExists(id));
        require(listingAvailable(id));

        uint requiredAmount = KM * listings[id].farePerKM;

        // Takes tokens from passenger
        require(token.transferFrom(msg.sender, this, requiredAmount));

        listings[id].lockedAmount = requiredAmount;

        LogTripStarted(msg.sender, listings[id].driverAddr, requiredAmount, destination, KM);
        return true;
    }

    function completeTrip(uint id, uint totalKM)
        public
        returns (bool)
    {
        require(listingExists(id));

        uint totalAmount = totalKM * listings[id].farePerKM;
        if (totalAmount > listings[id].lockedAmount)
            totalAmount = listings[id].lockedAmount;

        // send remaining amount to passenger
        uint remainingAmount = listings[id].lockedAmount - totalAmount;
        require(token.transfer(listings[id].passengerAddr, remainingAmount));

        // send payment to driver
        require(token.transfer(listings[id].driverAddr, totalAmount));

        listings[id].lockedAmount = 0;
        listings[id].passengerAddr = address(0);

        LogTripCompleted(msg.sender, listings[id].driverAddr, totalAmount, totalKM);
        return true;
    }

    function listingExists(uint id)
        public
        constant
        returns (bool)
    {
        return (listings[id].driverAddr != address(0));
    }

    function listingAvailable(uint id)
        public
        constant
        returns (bool)
    {
        return (listings[id].lockedAmount == 0);
    }

    function getListing(uint id)
        public
        constant
        returns(address, uint)
    {
        return (listings[id].driverAddr, listings[id].farePerKM);
    }

    function getListingCount()
        public
        constant
        returns(uint)
    {
        return listingsCnt;
    }
}
