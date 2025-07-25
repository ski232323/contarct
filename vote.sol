// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenBasedVoting is Ownable {
    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] public proposals;
    mapping(uint => mapping(address => bool)) public hasVoted;

    bool public votingActive;
    uint public winningProposalId;
    uint public currentVoteId;
    IERC20 public votingToken;

    constructor(address _tokenAddress) Ownable(msg.sender) { // <-- ici on passe msg.sender
        votingToken = IERC20(_tokenAddress);
    }

    function startNewVote(string[] calldata proposalDescriptions) external onlyOwner {
        require(!votingActive, "Voting already active");

        delete proposals;
        for (uint i = 0; i < proposalDescriptions.length; i++) {
            proposals.push(Proposal({
                description: proposalDescriptions[i],
                voteCount: 0
            }));
        }

        votingActive = true;
        winningProposalId = 0;
        currentVoteId += 1;
    }

    function vote(uint proposalId) external {
        require(votingActive, "Voting is not active");
        require(!hasVoted[currentVoteId][msg.sender], "Already voted in this vote");
        require(proposalId < proposals.length, "Invalid proposal");

        uint voterBalance = votingToken.balanceOf(msg.sender);
        require(voterBalance > 0, "Need voting tokens to vote");

        proposals[proposalId].voteCount += voterBalance;
        hasVoted[currentVoteId][msg.sender] = true;
    }

    function endVoting() external onlyOwner {
        require(votingActive, "Voting already ended");

        votingActive = false;
        uint maxVotes = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVotes) {
                maxVotes = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
    }

    function getWinningProposal() external view returns (string memory description, uint voteCount) {
        require(!votingActive, "Voting still active");
        Proposal storage winner = proposals[winningProposalId];
        return (winner.description, winner.voteCount);
    }

    function getProposalCount() external view returns (uint) {
        return proposals.length;
    }
}
