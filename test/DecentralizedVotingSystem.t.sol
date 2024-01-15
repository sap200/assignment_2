// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {DecentralizedVotingSystem} from "../src/DecentralizedVotingSystem.sol";

contract DecentralizedVotingSystemTest is Test {
    DecentralizedVotingSystem public decentralizedVotingSystem;
    string public title;
    string public description;

    function setUp() public {
        title = "Test_Election";
        description = "Test Election is designed for testing decentralized voting system smart contract";
        decentralizedVotingSystem = new DecentralizedVotingSystem(title, description);
    }

    // TestDescription: Test that title is same as passed in constructor
    function test_title() public {
        assertEq(decentralizedVotingSystem.title(), title);
    }

    // TestDescription: Test that description is same as passed in constructor
    function test_description() public {
        assertEq(decentralizedVotingSystem.description(), description);
    }

    // TestDescription: Test that initial election status is NOT_STARTED, i.e. election has not started yet
    // Expected: ElectionStatus is NOT_STARTED
    function test_initialElectionStatus() public {
        assertTrue(decentralizedVotingSystem.electionStatus() == DecentralizedVotingSystem.ElectionState.NOT_STARTED);
    }

    // TestDescription: Test that election can be started by the owner
    // Expected: Election status has changed to IN_PROGRESS
    function test_startElectionByOwner() public {
        vm.expectEmit(true, false, false, false, address(decentralizedVotingSystem));
        emit DecentralizedVotingSystem.ElectionStarted(block.timestamp);
        decentralizedVotingSystem.startElection();
        assertTrue(decentralizedVotingSystem.electionStatus() == DecentralizedVotingSystem.ElectionState.IN_PROGRESS);
    }

    // TestDescription: Test that a non-owner account cannot start the elections 
    // Expected: we expect a revert
    function test_startElectionByNonOwner() public {
        vm.expectRevert();
        // create a random address and send txn through the address
        address nonOwner = vm.addr(1);
        vm.prank(nonOwner);
        decentralizedVotingSystem.startElection();
        assertTrue(decentralizedVotingSystem.electionStatus() == DecentralizedVotingSystem.ElectionState.NOT_STARTED);
    }

    // TestDescription: Given election is in progress, the owner cannot start the election
    // Expected: We expect a revert 
    function test_startElectionWhenElectionIsInProgress() public {
        // start the election
        decentralizedVotingSystem.startElection();
        // Expect a revert with this message when election is already in progress
        vm.expectRevert("Election is already in progress or has stopped");
        decentralizedVotingSystem.startElection();
    }

    // TestDescription: Given, Election is in progress, Owner can stop the election
    // Expected: Electionstatus changes to STOPPED
    function test_stopElection() public {
        // start election
        decentralizedVotingSystem.startElection();
        assertTrue(decentralizedVotingSystem.electionStatus() == DecentralizedVotingSystem.ElectionState.IN_PROGRESS);

        // stop election
        vm.expectEmit(true, false, false, false, address(decentralizedVotingSystem));
        emit DecentralizedVotingSystem.ElectionStopped(block.timestamp);
        decentralizedVotingSystem.stopElection();
        assertTrue(decentralizedVotingSystem.electionStatus() == DecentralizedVotingSystem.ElectionState.STOPPED);
    }

    // TestDescription: Given, Non Owner tries to stop the election
    // Expected: Expect the election doesn't stops and electionStatus doesn't changes to STOPPED
    function test_stopElectionByNonOwner() public {
        // start election
        decentralizedVotingSystem.startElection();
        assertTrue(decentralizedVotingSystem.electionStatus() == DecentralizedVotingSystem.ElectionState.IN_PROGRESS);

        // create a random address and send txn through the address
        address nonOwner = vm.addr(1);
        vm.prank(nonOwner);
        vm.expectRevert();
        decentralizedVotingSystem.stopElection();
        assertTrue(decentralizedVotingSystem.electionStatus() == DecentralizedVotingSystem.ElectionState.IN_PROGRESS);
    }

    // TestDescription: Given, Election state is not started issue stop election command by owner
    // Expected: Expect a revert since election is not in progress
    function test_stopElectionWhenElectionStateIsNotStarted() public {
        vm.expectRevert("Election is not in progress");
        decentralizedVotingSystem.stopElection();
        assertTrue(decentralizedVotingSystem.electionStatus() == DecentralizedVotingSystem.ElectionState.NOT_STARTED);
    }

    // TestDescription: Given, Election state is stopped issue stop election command by owner
    // Expected: Expect a revert since election is not in progress
    function test_stopElectionWhenElectionStateIsStopped() public {
        // start and stop the election
        decentralizedVotingSystem.startElection();
        decentralizedVotingSystem.stopElection();

        vm.expectRevert("Election is not in progress");
        decentralizedVotingSystem.stopElection();
        assertTrue(decentralizedVotingSystem.electionStatus() == DecentralizedVotingSystem.ElectionState.STOPPED);
    }

    // TestDescription: Register a voter when election is in NOT_STARTED state
    // Expected: Voter is registered
    function test_registerVoterWhenElectionIsInNotStartedState() public {
        address voter = vm.addr(1);
        vm.expectEmit(true, false, false, false, address(decentralizedVotingSystem));
        emit DecentralizedVotingSystem.RegisteredAVoter(voter);
        vm.prank(voter);
        decentralizedVotingSystem.register();
        (bool isRegistered, bool hasVoted) = decentralizedVotingSystem.voters(voter); 
        assertTrue(isRegistered);
        assertFalse(hasVoted);
    }

    // TestDescription: Register a voter when election is in IN_PROGRESS state
    // Expected: Voter is registered successfully
    function test_registerVoterWhenElectionIsInProgressState() public {
        // start the election
        decentralizedVotingSystem.startElection();

        address voter = vm.addr(1);
        vm.expectEmit(true, false, false, false, address(decentralizedVotingSystem));
        emit DecentralizedVotingSystem.RegisteredAVoter(voter);
        vm.prank(voter);
        decentralizedVotingSystem.register();
        (bool isRegistered, bool hasVoted) = decentralizedVotingSystem.voters(voter); 
        assertTrue(isRegistered);
        assertFalse(hasVoted);
    }

    
    // TestDescription: Register a voter when election is in STOPPED state
    // Expected: Voter registration fails and we expect a revert
    function test_registerVoterWhenElectionIsInStoppedState() public {
        // start the election
        decentralizedVotingSystem.startElection();
        // stop the election
        decentralizedVotingSystem.stopElection();
        
        address voter = vm.addr(1);
        vm.prank(voter);
        vm.expectRevert("Election has stopped");
        decentralizedVotingSystem.register();
        (bool isRegistered, bool hasVoted) = decentralizedVotingSystem.voters(voter); 
        assertFalse(isRegistered);
        assertFalse(hasVoted);
    }

    // TestDescription: Register a voter who has already registered before
    // Expected: Registration fails and we expect a revert
    function test_registerVoterWhenHeIsAlreadyRegistered() public {
        address voter = vm.addr(1);
        vm.prank(voter);
        // register first
        decentralizedVotingSystem.register();

        // duplicate registrations
        vm.prank(voter);
        vm.expectRevert("Msg sender is already a registered voter");
        decentralizedVotingSystem.register();
        (bool isRegistered, bool hasVoted) = decentralizedVotingSystem.voters(voter); 
        assertTrue(isRegistered);
        assertFalse(hasVoted);   
    }

    // TestDescription: Owner adds a candidate when election has not started
    // Expected: Candidate is added successfully
    function test_addCandidateByOwnerWhenElectionHasNotStarted() public {
        string memory _name = "Candidate_A";
        decentralizedVotingSystem.addCandidate(_name);
        (string memory name, uint256 voteCount) = decentralizedVotingSystem.candidates(0);
        assertEq(name, _name);
        assertEq(voteCount, 0);
    }

    // TestDescription: Owner adds a candidate when election is in progress
    // Expected: Candidate is added successfully
    function test_addCandidateByOwnerWhenElectionIsInProgress() public {
        // start election
        decentralizedVotingSystem.startElection();

        // add candidate
        string memory _name = "Candidate_A";
        vm.expectEmit(false, false, false, true, address(decentralizedVotingSystem));
        emit DecentralizedVotingSystem.AddedACandidate(_name);
        decentralizedVotingSystem.addCandidate(_name);
        (string memory name, uint256 voteCount) = decentralizedVotingSystem.candidates(0);
        assertEq(name, _name);
        assertEq(voteCount, 0);
    }

    // TestDescription: Owner adds a candidate when election is in STOPPED state
    // Expected: Candidate is not added and we expect a revert
    function test_addCandidateByOwnerWhenElectionHasStopped() public {
        // Start and then stop the election
        decentralizedVotingSystem.startElection();
        decentralizedVotingSystem.stopElection();

        // Expect a revert when trying to add a candidate after the election has stopped
        vm.expectRevert("Election has stopped");
        decentralizedVotingSystem.addCandidate("Candidate_A");
    }

    // TestDescription: Non Owner tries to add a candidate
    // Expected: Candidate is not added and we expect a revert
    function test_addCandidateByNonOwner() public {
        vm.expectRevert();
        address nonOwner = vm.addr(1);
        vm.prank(nonOwner);
        decentralizedVotingSystem.addCandidate("Candidate_A");
    }

    // TestDescription: Voter, casts a vote for a valid candidate
    // Expected: Vote is recorded and voter's status is updated
    function test_castVote() public {
        // start election
        decentralizedVotingSystem.startElection();
        // add candidate
        decentralizedVotingSystem.addCandidate("CANDIDATE_A");

        // register voter
        address voter = vm.addr(1);
        vm.prank(voter);
        decentralizedVotingSystem.register();

        // caste a vote for candidate A
        vm.expectEmit(true, false, false, true, address(decentralizedVotingSystem));
        emit DecentralizedVotingSystem.VoteCasted(voter, 0);
        vm.prank(voter);
        decentralizedVotingSystem.castVote(0);

        (bool isRegistered, bool hasVoted) = decentralizedVotingSystem.voters(voter);
        assertTrue(hasVoted);
        assertTrue(isRegistered);

        (string memory _name, uint256 voteCount) = decentralizedVotingSystem.candidates(0);
        assertEq("CANDIDATE_A", _name);
        assertEq(voteCount, 1);
    }

    // Test Description: Voter, casts a vote for invalid candidate
    // Expected: We expect a revert
    function test_castVoteInvalidCandidate() public {
        // start election
        decentralizedVotingSystem.startElection();

         // register voter
        address voter = vm.addr(1);
        vm.prank(voter);
        decentralizedVotingSystem.register();

        // caste a vote for candidate A
        vm.prank(voter);
        vm.expectRevert("Invalid index of candidate");
        decentralizedVotingSystem.castVote(0);
    }

    // Test Description: Voter, casts a vote when election is not in progress state
    // Expected: We expect a revert
    function test_castVoteWhenElectionIsNotInProgressState() public {
         // register voter
        address voter = vm.addr(1);
        vm.prank(voter);
        decentralizedVotingSystem.register();

        // caste a vote for candidate A
        vm.prank(voter);
        vm.expectRevert("Election is not in progress");
        decentralizedVotingSystem.castVote(0);
    }

    // Test Description: Unregistered voter casts a vote
    // Expected: We expect a revert
    function test_castVoteByUnregisteredUser() public {
        // start election
        decentralizedVotingSystem.startElection();

        address voter = vm.addr(1);
        vm.prank(voter);
        vm.expectRevert("Msg sender is not registered");
        decentralizedVotingSystem.castVote(0);   
    }

    // TestDescription: Try casting duplicate vote
    // Expected: We expect a revert
    function test_castDuplicateVoteByVoter() public {
        // start election
        decentralizedVotingSystem.startElection();
        // add candidate
        decentralizedVotingSystem.addCandidate("CANDIDATE_A");

        // register voter
        address voter = vm.addr(1);
        vm.prank(voter);
        decentralizedVotingSystem.register();

        // caste a vote for candidate A
        vm.prank(voter);
        decentralizedVotingSystem.castVote(0);

        vm.prank(voter);
        vm.expectRevert("Msg sender has already voted");
        decentralizedVotingSystem.castVote(0);

        (bool isRegistered, bool hasVoted) = decentralizedVotingSystem.voters(voter);
        assertTrue(hasVoted);
        assertTrue(isRegistered);

        (string memory _name, uint256 voteCount) = decentralizedVotingSystem.candidates(0);
        assertEq("CANDIDATE_A", _name);
        assertEq(voteCount, 1);
    }
}
