# Decentralized Voting System

## Introduction

This repository contains the implementation of a decentralized voting system smart contract using Solidity.

## Design Choices

- When deploying the contract for a specific election or poll, it's important to provide a name and description for clarity.
- Enums are used to represent the state of the election, including "NOT_STARTED," "IN_PROGRESS," and "STOPPED." This allows flexibility in setting up elections and adding participants before starting.
- Modifiers like `hasNotVotedYet` and `isElectionLive` are used to make the code modularized and reduce redundancy.
- To ensure transparency, key variables are made public, enabling anyone to inspect the contract's state.
- A `viewResults` function is provided for result retrieval, determining the winner on-chain will require a for loop and hence I have left it to be done off-chain in the frontend.
- The `stopElection` function allows the contract owner to control the election thereby maintaining customizability.

## Security Considerations

- A `hasNotVotedYet` modifier is in place to prevent double voting, maintaining the integrity of the election.
- Candidate index validation is implemented, ensuring that an invalid candidate index provided by a user will trigger an EVM revert.
- Checks on `electionState` ensure that only registered voters can cast their votes when the election is in progress.
- The contract inherits the OpenZeppelin `Ownable` interface for secure access control.
- Safe math operations are used to prevent overflow and underflow vulnerabilities, enhancing the contract's security.

## Test Cases

## Key Features

- **User Registration**: Users can register to vote, ensuring that only eligible participants can cast their votes.

- **Candidate Management**: The owner of the contract has the authority to add candidates to the election, allowing for a dynamic list of candidates.

- **Secure Voting**: Registered voters can securely cast their votes for their preferred candidate, with mechanisms in place to prevent multiple votes from the same user.

- **Transparency**: The voting process is transparent, ensuring that the results are publicly accessible to maintain trust in the election process.

## Implementation

The implementation of this decentralized voting system is done using Solidity, a popular programming language for creating smart contracts on blockchain platforms. The contract employs appropriate data structures to store voter information and election results. Events are used to log important actions, providing transparency and auditability.

## Requirements

The project's requirements include:

- Implementation of the smart contract in Solidity.
- Proper use of data structures to store voter information and election results.
- Ensuring that voters can only cast one vote.
- Inclusion of events to log essential actions during the voting process.
