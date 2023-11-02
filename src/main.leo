program vote.aleo {
    // Proposal details
    struct ProposalInfo {
        title: field,
        content: field,
        proposer: address,
    }

    // Proposal record records proposal info publicly
    record Proposal {
        owner: address,
        gates: u64,
        id: field,
        info: ProposalInfo,
    }

    // Save proposal info in public storage.
    mapping proposals: field => ProposalInfo;

    // Privacy tickets to vote
    record Ticket {
        owner: address,
        gates: u64,
        pid: field,
    }

    // Count the total tickets issued for each proposal
    mapping tickets: field => u64;

    mapping agree_votes: field => u64;

    mapping disagree_votes: field => u64;

    // Propose a new proposal to vote on.
    transition propose(public info: ProposalInfo) -> Proposal {
        // Authenticate proposer.
        assert_eq(self.caller, info.proposer);

        // Generate a new proposal id.
        let id: field = BHP256::hash(info.title);

        // Return a new record for the proposal.
        // Finalize the proposal id.
        return Proposal {
            owner: self.caller,
            gates: 0u64,
            id,
            info,
        } then finalize(id);
    }
    // Create a new proposal in the "tickets" mapping.
    finalize propose(public id: field) {
        Mapping::set(tickets, id, 0u64);
    }

    // Create a new ticket to vote with.
    transition new_ticket(
        public pid: field,
        public voter: address,
    ) -> Ticket {
        // Finalize the proposal id for the ticket.
        return Ticket {
            owner: voter,
            gates: 0u64,
            pid,
        } then finalize(pid);
    }
    // Create a new ticket on a proposal in the "tickets" mapping.
    finalize new_ticket(public pid: field) {
        let vote: u64 = Mapping::get_or_init(tickets, pid, 0u64);
        Mapping::set(tickets, pid, vote + 1u64);
    }

    // Vote privately to agree with a proposal.
    transition agree(ticket: Ticket) {
        // Finalize this vote.
        return then finalize(ticket.pid);
    }
    finalize agree(public pid: field) {
        // Publicly increment the number of agree votes.
        let agree_vote: u64 = Mapping::get_or_init(agree_votes, pid, 0u64);
        Mapping::set(agree_votes, pid, agree_vote + 1u64);
    }

    // Vote privately to disagree with a proposal.
    transition disagree(ticket: Ticket) {
        // Finalize this vote.
        return then finalize(ticket.pid);
    }
    finalize disagree(pid: field) {
        // Publicly increment the number of disagree votes.
        let disagree_vote: u64 = Mapping::get_or_init(disagree_votes, pid, 0u64);
        Mapping::set(disagree_votes, pid, disagree_vote + 1u64);
    }
    transition delete_proposal (proposal: field) -> ProposalInfo {
        let proposal_info: ProposalInfo = Mapping::get(proposals, proposal);
        return proposal_info then finalize(proposal);
    }
    finalize delete_proposal (proposal) {
        let remove_proposal: () = Mapping::remove(proposals, proposal);
    }
    transition change_proposal_id (existing_proposal_id: field, new_proposal_id: field) -> ProposalInfo {
        let proposal: ProposalInfo = Mapping::get(proposals, existing_proposal_id);
        return proposal then finalize(proposal, new_proposal_id);
    }
    finalize change_proposal_id (proposal: ProposalInfo, new_proposal_id: field) {
        Mapping::set(proposals, new_proposal_id, proposal);
    }
}
