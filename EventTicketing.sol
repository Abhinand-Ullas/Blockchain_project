// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TicketingSystem {   
    struct Event {           //details of the event 
        string name;
        uint256 date; // UNIX timestamp
        uint256 ticketPrice;
        uint256 ticketsAvailable;
        address organizer;
        bool exists;
        bool cancelled;
    }
    mapping(uint256 => mapping(address => uint8)) public reviews;   //review of events by each user
    mapping(uint256 => uint256) public totalRatings;   //sum of ratings of each event
    mapping(uint256 => uint256) public numReviews;     //total number of reviews
    uint256 public eventIdCounter;
    mapping(uint256 => Event) public events;    //events mapped using event id
    mapping(uint256 => uint256) public EventFunds;  //total funds of each event
    mapping(uint256 => mapping(address => uint256)) public ticketsOwned;  //tickets owned by each user for each event
    event EventCreated(uint256 eventId, string name, uint256 date, uint256 ticketPrice, uint256 ticketsAvailable);
    event TicketPurchased(uint256 eventId, address buyer, uint256 quantity);
    event Withdrawal(address organizer, uint256 amount);
    event Refunded(uint256 eventId, address attendee, uint256 amount);
    event EventCancelled(uint256 eventId);
    modifier eventExists(uint256 _eventId) {       //checking existence of event 
        require(events[_eventId].exists, "Event does not exist");
        _;
    }

    function createEvent(string memory _name, uint256 _date, uint256 _ticketPrice, uint256 _tickets) public {
        require(_date > block.timestamp, "Event must be in the future");
        require(_ticketPrice > 0, "Ticket price must be greater than 0");

        events[eventIdCounter] = Event({
            name: _name,
            date: _date,
            ticketPrice: _ticketPrice,
            ticketsAvailable: _tickets,
            organizer: msg.sender,
            exists: true,
            cancelled:false
        });

        emit EventCreated(eventIdCounter, _name, _date, _ticketPrice, _tickets);
        eventIdCounter++;
    }

    function buyTickets(uint256 _eventId, uint256 _quantity) public payable eventExists(_eventId) {
        Event storage myEvent = events[_eventId];
        require(!events[_eventId].cancelled,"Event has been cancelled");
        require(block.timestamp < myEvent.date, "Event already happened");
        require(_quantity > 0, "Quantity must be at least 1");
        require(_quantity <= myEvent.ticketsAvailable, "Not enough tickets");
        require(msg.value >= _quantity * myEvent.ticketPrice, "Insufficient ETH");
        uint256 required=_quantity * myEvent.ticketPrice;   //required eth
        if(msg.value>required){
           (bool success, ) = payable(msg.sender).call{value: msg.value-required}("");   //sending back excess eth if required
        require(success, "Withdraw failed");
        }
        EventFunds[_eventId]+=msg.value;      //updating amount send for each event
        myEvent.ticketsAvailable -= _quantity;  //updating number of tickets remaining
        ticketsOwned[_eventId][msg.sender] += _quantity;  //updating the tickets of users

        emit TicketPurchased(_eventId, msg.sender, _quantity);
    }

    function withdrawFunds(uint256 _eventId) public eventExists(_eventId) {
        Event storage myEvent = events[_eventId];
        require(msg.sender == myEvent.organizer, "Only organizer can withdraw");
        require(block.timestamp > myEvent.date, "Cannot withdraw before event");

        uint256 balance = EventFunds[_eventId];  //obtaining amount of each event
        EventFunds[_eventId]=0;  //making the amount of that event 0
        (bool success, ) = payable(myEvent.organizer).call{value: balance}("");  //withdrawing to organizers account
        require(success, "Withdraw failed");
        emit Withdrawal(myEvent.organizer, balance);
    }

    function getMyTickets(uint256 _eventId) public view returns (uint256) {
        return ticketsOwned[_eventId][msg.sender];  //gives number of tickets of the sender
    }
    function review(uint256 _eventId,uint8 rating) public eventExists(_eventId){
        require(ticketsOwned[_eventId][msg.sender] > 0, "Only attendees can review"); 
        require(reviews[_eventId][msg.sender]==0,"cannot review twice"); //restricting multple review from same user
        require(rating>0 && rating<=5,"rating must be greater than 0 and less than 5");
        require(block.timestamp>events[_eventId].date,"cannot review before event");
        reviews[_eventId][msg.sender]=rating;
        totalRatings[_eventId]+=rating;
        numReviews[_eventId]++;
    }
     function getRating(uint256 _eventId) public view returns (uint256){
        require(block.timestamp>events[_eventId].date,"cannot check review before event");
        require(numReviews[_eventId] > 0, "No reviews yet");
        return (totalRatings[_eventId] / numReviews[_eventId]); //obtaining average rating
    }
    function refund(uint256 _eventId) public eventExists(_eventId){
        require(events[_eventId].cancelled || block.timestamp<(events[_eventId].date-(1 days)),"You must apply for refund atleast 24 hours before the event or event must be cancelled");
        require(ticketsOwned[_eventId][msg.sender] > 0, "Only attendees can get refund");
        uint256 Refund=ticketsOwned[_eventId][msg.sender]*events[_eventId].ticketPrice; //calculating refund money
        EventFunds[_eventId]-=Refund; //updating funds of the event
        events[_eventId].ticketsAvailable+=ticketsOwned[_eventId][msg.sender]; //updating available tickets
        ticketsOwned[_eventId][msg.sender]=0;  //updating the number of tickets owned by the sender
        (bool success, ) = payable(msg.sender).call{value: Refund}("");  //refunding to sender's account
        require(success, "Withdraw failed");
        
        emit Refunded(_eventId,msg.sender,Refund);
    }
    function CancelEvent(uint256 _eventId) public eventExists(_eventId){
        require(events[_eventId].exists,"Event does not exist");
        require(msg.sender==events[_eventId].organizer,"Only organizer can cancel event");
        require(block.timestamp<events[_eventId].date,"Event has already happened");
        require(!events[_eventId].cancelled,"Event has already been cancelled");
        events[_eventId].cancelled=true;
        emit EventCancelled(_eventId);
    }
    function GetEventStatus(uint256 _eventId) public eventExists(_eventId) view returns (string memory){
         if(events[_eventId].cancelled==true) return "Cancelled";
         if(events[_eventId].date>block.timestamp)  return "Upcoming";
            return "Completed";
         }   
    receive() external payable {}
}
