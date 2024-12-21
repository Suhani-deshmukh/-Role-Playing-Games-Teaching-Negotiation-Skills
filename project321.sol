// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NegotiationGame {
    enum Role { None, Buyer, Seller, Mediator }
    enum Status { Pending, Agreed, Disputed }

    struct Player {
        address addr;
        Role role;
        uint256 score;
    }

    struct Negotiation {
        uint256 id;
        address buyer;
        address seller;
        address mediator;
        string buyerOffer;
        string sellerOffer;
        Status status;
    }

    Player[] public players;
    Negotiation[] public negotiations;

    mapping(address => Role) public roles;
    mapping(address => uint256) public scores;

    event PlayerRegistered(address indexed player, Role role);
    event NegotiationStarted(uint256 indexed negotiationId, address buyer, address seller);
    event OfferMade(uint256 indexed negotiationId, address player, string offer);
    event AgreementReached(uint256 indexed negotiationId);
    event DisputeRaised(uint256 indexed negotiationId);

    modifier onlyRole(Role _role) {
        require(roles[msg.sender] == _role, "Unauthorized role");
        _;
    }

    modifier validNegotiation(uint256 _id) {
        require(_id < negotiations.length, "Invalid negotiation ID");
        _;
    }

    function registerPlayer(Role _role) public {
        require(roles[msg.sender] == Role.None, "Already registered");
        require(_role != Role.None, "Invalid role");
        roles[msg.sender] = _role;
        players.push(Player(msg.sender, _role, 0));
        emit PlayerRegistered(msg.sender, _role);
    }

    function startNegotiation(address _seller, address _mediator) public onlyRole(Role.Buyer) {
        require(roles[_seller] == Role.Seller, "Selected seller is not registered");
        require(roles[_mediator] == Role.Mediator, "Selected mediator is not registered");

        negotiations.push(Negotiation({
            id: negotiations.length,
            buyer: msg.sender,
            seller: _seller,
            mediator: _mediator,
            buyerOffer: "",
            sellerOffer: "",
            status: Status.Pending
        }));

        emit NegotiationStarted(negotiations.length - 1, msg.sender, _seller);
    }

    function makeOffer(uint256 _negotiationId, string memory _offer) 
        public 
        validNegotiation(_negotiationId) 
    {
        Negotiation storage negotiation = negotiations[_negotiationId];
        require(negotiation.status == Status.Pending, "Negotiation is not active");

        if (msg.sender == negotiation.buyer) {
            negotiation.buyerOffer = _offer;
        } else if (msg.sender == negotiation.seller) {
            negotiation.sellerOffer = _offer;
        } else {
            revert("You are not part of this negotiation");
        }

        emit OfferMade(_negotiationId, msg.sender, _offer);
    }

    function finalizeAgreement(uint256 _negotiationId) 
        public 
        validNegotiation(_negotiationId) 
        onlyRole(Role.Mediator) 
    {
        Negotiation storage negotiation = negotiations[_negotiationId];
        require(negotiation.status == Status.Pending, "Negotiation is already closed");
        require(bytes(negotiation.buyerOffer).length > 0, "Buyer has not made an offer");
        require(bytes(negotiation.sellerOffer).length > 0, "Seller has not made an offer");

        negotiation.status = Status.Agreed;
        scores[negotiation.buyer] += 1;
        scores[negotiation.seller] += 1;

        emit AgreementReached(_negotiationId);
    }

    function raiseDispute(uint256 _negotiationId) 
        public 
        validNegotiation(_negotiationId) 
    {
        Negotiation storage negotiation = negotiations[_negotiationId];
        require(negotiation.status == Status.Pending, "Negotiation is already closed");
        negotiation.status = Status.Disputed;

        emit DisputeRaised(_negotiationId);
    }

    function getPlayers() public view returns (Player[] memory) {
        return players;
    }

    function getNegotiations() public view returns (Negotiation[] memory) {
        return negotiations;
    }
}