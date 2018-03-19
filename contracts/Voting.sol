pragma solidity ^0.4.18;

import "./EIP20/EIP20.sol";

contract Voting {

    event LogVoteCommitted(address sender, uint pollId, uint amount);
    event LogVoteRevealed(address sender, uint pollId, uint numTokens, bool doesAccept);
    event LogPollStarted(uint voteThreshold, uint commitDuration, uint revealDuration, uint pollId);


    uint constant public ACCEPT_RATIO = 70;
    uint constant public COMMIT_DATE = 100;
    uint constant public REVEAL_DATE = 50;

    struct Poll {
        uint commitEndDate; // expiration date of commit period
        uint revealEndDate; // expiration date of reveal period
        uint acceptCnt;     // number of accepting tokens
        uint rejectCnt;     // number of rejecting tokens
        uint acceptRatio;   // minimum ratio required for accepting
    }

    // ============
    // STATE VARIABLES:
    // ============

    uint public pollCnt;

    mapping(uint => Poll) public pollMap;
    mapping(bytes32 => uint) private hiddenMessages;

    EIP20 public token;

    // ============
    // CONSTRUCTOR:
    // ============

    /**
     * Constructor
     * @param tokenAddr ERC20 token contract address.
     */
    function Voting(address tokenAddr)
        public
    {
        token = EIP20(tokenAddr);
        pollCnt = 0;
    }

    // =================
    // VOTING INTERFACE:
    // =================

    /**
     * Called by a token holder.
     * Commits vote using hash of choice and secret salt to conceal vote until reveal
     * @param pollId driver address that is being voted
     * @param secretHash Commit keccak256 hash of voter's choice and salt (tightly packed in this order)
     * @param amount The number of tokens to be committed towards the target poll
     * Emits LogVoteCommitted.
     */
    function commitVote(uint pollId, bytes32 secretHash, uint amount)
        public
    {
        require(duringCommitPeriod(pollId));
        require(token.transferFrom(msg.sender, this, amount));

        bytes32 UUID = keccak256(msg.sender, pollId);
        saveHiddenMessage(UUID, "amount", amount);
        saveHiddenMessage(UUID, "hash", uint(secretHash));

        LogVoteCommitted(msg.sender, pollId, amount);
    }


    /**
     * Called by a token holder.
     * Reveals vote with choice and secret salt used in generating commitHash to attribute committed tokens
     * @param pollId Integer identifier associated with target poll
     * @param doesAccept Vote choice used to generate commitHash for associated poll
     * @param salt Secret number used to generate commitHash for associated poll
     * Emits LogVoteRevealed.
     */
    function revealVote(uint pollId, bool doesAccept, uint salt) external {
        require(pollExists(pollId));
        require(duringRevealPeriod(pollId));
        //(!isRevealed(msg.sender, pollId)); // prevent user from revealing multiple times
        require(salt != 0);
        //require(keccak256(_voteOption, _salt) == getCommitHash(msg.sender, pollId)); // compare resultant hash from inputs to original commitHash

        uint amount = getHiddenMessage(getUUID(msg.sender, pollId), "amount");

        if (doesAccept == true)
            pollMap[pollId].acceptCnt += amount;
        else
            pollMap[pollId].rejectCnt += amount;

        removeVote(msg.sender, pollId);

        LogVoteRevealed(msg.sender, pollId, amount, doesAccept);
    }

    /**
    @dev Unlocks tokens locked in unrevealed vote where poll has ended
    @param pollId Integer identifier associated with the target poll
    */
    function rescueTokens(uint pollId)
        public
    {
        require(isPollFinished(pollId));
        //require(!isRevealed(msg.sender, pollId));

        removeVote(msg.sender, pollId);
    }


    // ==================
    // POLLING INTERFACE:
    // ==================

    /**
    @dev Initiates a poll with canonical configured parameters at pollId emitted by PollCreated event
    @param acceptRatio Type of majority (out of 100) that is necessary for poll to be successful
    @param commitDuration Length of desired commit period in seconds
    @param revealDuration Length of desired reveal period in seconds
    */
    function startPoll(uint acceptRatio, uint commitDuration, uint revealDuration)
        public
        returns (uint)
    {
        pollCnt = pollCnt + 1;

        pollMap[pollCnt] = Poll({
            acceptRatio: acceptRatio,
            commitEndDate: block.timestamp + commitDuration,
            revealEndDate: block.timestamp + commitDuration + revealDuration,
            acceptCnt: 0,
            rejectCnt: 0
        });

        LogPollStarted(acceptRatio, commitDuration, revealDuration, pollCnt);
        return pollCnt;
    }

    function isAccepted(uint pollId)
        constant
        public
        returns (bool)
    {
        require(isPollFinished(pollId));

        Poll memory poll = pollMap[pollId];
        return (100 * poll.acceptCnt) > (poll.acceptRatio * (poll.acceptCnt + poll.rejectCnt));
    }

    function isPollFinished(uint pollId)
        constant
        public
        returns (bool)
    {
        require(pollMap[pollId].revealEndDate > block.timestamp);

        return true;
    }

    function duringCommitPeriod(uint pollId)
        constant
        public
        returns (bool)
    {
        require(pollMap[pollId].commitEndDate <= block.timestamp);

        return true;
    }

    function duringRevealPeriod(uint pollId)
        constant
        public
        returns (bool)
    {
        require(pollMap[pollId].revealEndDate <= block.timestamp);
        require(pollMap[pollId].commitEndDate > block.timestamp);

        return true;
    }

    function pollExists(uint pollId)
        constant
        public
        returns (bool exists)
    {
        require(pollMap[pollId].commitEndDate != 0);
        require(pollMap[pollId].revealEndDate != 0);
        require(pollMap[pollId].acceptRatio != 0);

        return true;
    }

    function saveHiddenMessage(bytes32 UUID, string key, uint value)
        private
    {
        bytes32 hashKey = keccak256(UUID, key);
        hiddenMessages[hashKey] = value;
    }

    function getHiddenMessage(bytes32 UUID, string key)
        constant
        public
        returns (uint)
    {
        bytes32 hashkey = keccak256(UUID, key);
        return hiddenMessages[hashkey];
    }

    function removeHiddenMessage(uint UUID, string key)
        private
    {
        bytes32 hashkey = keccak256(UUID, key);
        delete hiddenMessages[hashkey];
    }

    function getUUID(address sender, uint pollId)
        pure
        public
        returns (bytes32)
    {
        return keccak256(sender, pollId);
    }

    function voteExists(address sender, uint pollId)
        constant
        public
        returns (bool)
    {
        require(getHiddenMessage(getUUID(sender, pollId), "amount") != 0);
        require(getHiddenMessage(getUUID(sender, pollId), "hash") != 0);

        return true;
    }

    function removeVote(address sender, uint pollId)
        private
    {
        require(voteExists(sender, pollId));

        uint amount = hiddenMessages[keccak256(getUUID(sender, pollId), "amount")];
        require(token.transfer(sender, amount));    // send tokens back to voter

        delete hiddenMessages[keccak256(getUUID(sender, pollId), "amount")];
        delete hiddenMessages[keccak256(getUUID(sender, pollId), "hash")];
    }

}
