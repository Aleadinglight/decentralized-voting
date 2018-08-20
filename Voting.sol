pragma solidity ^0.4.24;

contract Ballot{
    // This struct represent a single voter
    struct Voter {
        // delegate means assign someone you trust to do the voting for you
        uint weight; // this is accumulated by delegation
        bool is_voted; // check if this person is voted or not
        address delegate; // the person delegated to
        uint vote_result;
    }
    
    // This struct represent a single proposal - the candidate
    struct Proposal{
        bytes32 name;
        uint voteCount; // number of accumulated vote_result
    }
    
    // This is the one who created the contract
    address public chairperson;
    
    // Each voter struct is stored in an address
    mapping(address => Voter) public voters;
    
    // An array of Proposal structs
    Proposal[] public proposals;
    
    // Create a new ballot to choose one of proposal name
    // this proposalNames is the name of all proposals
    constructor(bytes32[] proposalNames) public{
        // The chairperson is the one who created the contract
        chairperson = msg.sender;
        // He already has 1 vote
        voters[chairperson].weight = 1;
        
        // Now create a new proposal object for each person
        for (uint i = 0; i<proposalNames.length; i++){
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    // Give voter the right to voter
    // Can only be called by the chairperson
    function giveRightToVote(address voter) public{
        // If the first argument of `require` evaluates
        // to `false`, execution terminates and all
        // changes to the state and to Ether balances
        // are reverted.
        // This used to consume all gas in old EVM versions, but
        // not anymore.
        require(
            msg.sender == chairperson,
            // explanation about what went wrong.
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].is_voted,
            "This person already voted."
        );
        // This person must not be given vote right before
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }
    
    // Delegate your vote to the voter "to"
    function delegate(address to) public{
        // assign reference
        Voter storage sender = voters[msg.sender];
        require(!sender.is_voted,"You already voted.");
        
        require(to != msg.sender, "self-delegation is disallowed.");
        
        // Forward the delegation as long as
        // `to` also delegated.
        // In general, such loops are very dangerous,
        // because if they run too long, they might
        // need more gas than is available in a block.
        // In this case, the delegation will not be executed,
        // but in other situations, such loops might
        // cause a contract to get "stuck" completely.
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        
        // Since `sender` is a reference, this
        // modifies `voters[msg.sender].voted`
        sender.is_voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.is_voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            proposals[delegate_.vote_result].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }
    
    // Give your vote (including votes delegated to you)
    // to proposal `proposals[proposal].name`.
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.is_voted, "Already voted.");
    
        sender.is_voted = true;
        sender.vote_result = proposal;
        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }
    
    // Return the winner index
    function winningProposal() public view 
        returns(uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint i = 0; i<proposals.length; i++){
            if (proposals[i].voteCount > winningVoteCount){
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
       }
    }
    
    // Return the winner name
    function winnerName() public view
        returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;        
    }
}
