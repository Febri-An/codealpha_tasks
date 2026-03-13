// SPDX-License-Identifier: MIT
pragma solidity 0.8.31;

contract PollingSystem {

    enum Option { Agree, Disagree }

    struct Poll {
        string title;
        uint256 endTime;
        mapping(Option => uint256) voteCounts;
        mapping(address => bool) hasVoted;
        bool exists;
    }

    uint256 public pollCount;
    mapping(uint256 => Poll) private polls;

    event PollCreated(uint256 pollId, string title, uint256 endTime);
    event Voted(uint256 pollId, address voter, Option option);

    // ─── Create Poll ───────────────────────────────────────────
    function createPoll(
        string calldata _title,
        uint256 _durationInSeconds
    ) external returns (uint256 pollId) {
        require(_durationInSeconds > 0, "Duration must be > 0");

        pollId = pollCount++;
        Poll storage p = polls[pollId];
        p.title = _title;
        p.endTime = block.timestamp + _durationInSeconds;
        p.exists = true;

        emit PollCreated(pollId, _title, p.endTime);
    }

    // ─── Vote ──────────────────────────────────────────────────
    function vote(uint256 _pollId, Option _option) external {
        Poll storage p = polls[_pollId];

        require(p.exists, "Poll does not exist");
        require(block.timestamp < p.endTime, "Poll has ended");
        require(!p.hasVoted[msg.sender], "You have already voted");

        p.hasVoted[msg.sender] = true;
        p.voteCounts[_option]++;

        emit Voted(_pollId, msg.sender, _option);
    }

    // ─── Get Winner ────────────────────────────────────────────
    function getWinner(uint256 _pollId)
        external
        view
        returns (string memory winnerOption, uint256 winnerVotes)
    {
        Poll storage p = polls[_pollId];

        require(p.exists, "Poll does not exist");
        require(block.timestamp >= p.endTime, "Poll has not ended yet");

        uint256 agreeVotes = p.voteCounts[Option.Agree];
        uint256 disagreeVotes = p.voteCounts[Option.Disagree];

        if (agreeVotes >= disagreeVotes) {
            return ("Agree", agreeVotes);
        } else {
            return ("Disagree", disagreeVotes);
        }
    }

    // ─── View Helpers ──────────────────────────────────────────
    function getPollInfo(uint256 _pollId)
        external
        view
        returns (string memory title, uint256 endTime)
    {
        Poll storage p = polls[_pollId];
        require(p.exists, "Poll does not exist");
        return (p.title, p.endTime);
    }

    function getVoteCount(uint256 _pollId, Option _option)
        external
        view
        returns (uint256)
    {
        Poll storage p = polls[_pollId];
        require(p.exists, "Poll does not exist");
        return p.voteCounts[_option];
    }
}
