// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedVotingSystem is Ownable {
    using SafeMath for uint256;

    enum ElectionState {
        NOT_STARTED,
        IN_PROGRESS,
        STOPPED
    }

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
    }

    string public title;
    string public description;
    ElectionState public electionStatus;

    mapping(address => Voter) public voters;
    Candidate[] public candidates;

    event RegisteredAVoter(address indexed voterAddress);
    event AddedACandidate(string candidateName);
    event VoteCasted(address indexed voterAddress, uint256 candidateIdx);
    event ElectionStarted(uint256 indexed timestamp);
    event ElectionStopped(uint256 indexed timestamp);

    modifier hasNotVotedYet() {
        require(
            voters[msg.sender].hasVoted == false,
            "Msg sender has already voted"
        );
        _;
    }

    modifier isRegisteredVoter() {
        require(
            voters[msg.sender].isRegistered,
            "Msg sender is not registered"
        );
        _;
    }

    modifier isElectionLive() {
        require(
            electionStatus == ElectionState.IN_PROGRESS,
            "Election is not in progress"
        );
        _;
    }

    modifier isElectionNotStopped() {
        require(
            electionStatus != ElectionState.STOPPED,
            "Election has stopped"
        );
        _;
    }

    constructor(string memory _title, string memory _description)
        Ownable(msg.sender)
    {
        title = _title;
        description = _description;
    }

    function startElection() external onlyOwner {
        require(
            electionStatus == ElectionState.NOT_STARTED,
            "Election is already in progress or has stopped"
        );
        electionStatus = ElectionState.IN_PROGRESS;
        emit ElectionStarted(block.timestamp);
    }

    function stopElection() external isElectionLive onlyOwner {
        electionStatus = ElectionState.STOPPED;
        emit ElectionStopped(block.timestamp);
    }

    function register() external isElectionNotStopped {
        require(
            voters[msg.sender].isRegistered == false,
            "Msg sender is already a registered voter"
        );
        voters[msg.sender].isRegistered = true;
        // by default hasVoted will be false
        emit RegisteredAVoter(msg.sender);
    }

    function addCandidate(string memory _candidateName)
        external
        isElectionNotStopped
        onlyOwner
    {
        candidates.push(Candidate({name: _candidateName, voteCount: 0}));
        emit AddedACandidate(_candidateName);
    }

    function castVote(uint256 _candidateIdx)
        external
        isElectionLive
        isRegisteredVoter
        hasNotVotedYet
    {
        require(
            _candidateIdx >= 0 && _candidateIdx < candidates.length,
            "Invalid index of candidate"
        );
        voters[msg.sender].hasVoted = true;
        // increment candidate's votecount
        candidates[_candidateIdx].voteCount = candidates[_candidateIdx]
            .voteCount
            .add(1);
        emit VoteCasted(msg.sender, _candidateIdx);
    }

    function viewResults() external view returns (Candidate[] memory) {
        return candidates;
    }
}
