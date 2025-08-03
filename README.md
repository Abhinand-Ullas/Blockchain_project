# Blockchain_project
This is a solidity code written on Remix IDE.The smart contract given here is of a Event Ticketing System.It is successfully tested on sepolia testnet.
This contract includes the following features and techniques:
** Creating an event by inputing all the essential details such as name,date,ticket price and ticket availability
** Buying the ticket by providing the required eth.All necessary conditions being checked to ensure security.If excess amount is sent,it will be resend
** The contract organizer can withdraw the amount of a particular event after the event is completed
** The organizer can cancel the event in case of any unforeseen circumstances.
** The sender can ask for refund atleast 24 hours before the event or if the event is cancelled
** The attendee can review the event,once the event is over.The review can't be edited
** Sender can also view the ratings of an event,so that they can decide the quality of similar events
** GetMyTickets function to view the tickets of the attendee
** One can view the status of the event,whether the event is cancelled,upcoming or completed

-Re-entrancy tests have been performed,and potential issues have been rectified.
-The contract adress obtained through sepolia testnet is provided here: 0x1a883cc99126246cd5026898b1f8638208dd4ca6
