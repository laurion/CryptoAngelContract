pragma solidity 0.4.8;

contract Crowdfunding {
    
    address public OWNER;
    uint public raiseTarget; // required to reach at least this much, else everyone gets refund

    // Data structures
    enum State {
        Fundraising,
        ExpiredRefund,
        Successful,
        Closed
    }

    struct Contribution {
        uint amount;
        address contributor;
    }

    struct Beneficiary {
        uint percentage;
        address beneficiary;
    }

    // State variables
    State public state = State.Fundraising; // initialize on create
    uint public totalRaised;
    uint public currentBalance;
    uint public _startTime;
    uint public _endTime;
    uint public completeAt;
    Contribution[] contributions;
    Beneficiary[] fundBeneficiaries;

    event LogFundingReceived(address addr, uint amount, uint currentTotal);
    event LogWinnersPaid(address winnerAddress);
    event LogFunderInitialized(
        address owner,
        uint _raiseTarget, 
        uint256 startTime,
        uint256 endTime
    );

    modifier inState(State _state) {
        if (state != _state) revert();
        _;
    }

    modifier isOwner() {
        if (msg.sender != OWNER) revert();
        _;
    }

    // Wait 1 hour after final contract state before allowing contract destruction
    modifier atEndOfLifecycle() {
        if(!((state == State.ExpiredRefund || state == State.Successful) && completeAt + 1 hours < now)) {
            revert();
        }
        _;
    }

    constructor(
        uint __startTime,
        uint __endTime,
        uint _raiseTarget)
    {
        OWNER = msg.sender;
        raiseTarget = _raiseTarget * 1000000000000000000; //convert to wei
        _startTime = __startTime;
        _endTime = __endTime;
        currentBalance = 0;
        emit LogFunderInitialized(
            OWNER,
            raiseTarget,
            _startTime,
            _endTime);
    }

    function totalPercentage() public returns (uint) {
        return totalRaised * 100 / raiseTarget;
    }

    function target() public returns (uint) {
        return raiseTarget;
    }

    function startTime() public returns (uint) {
        return _startTime;
    }

    function endTime() public returns (uint) {
        return _endTime;
    }

    function raised() public returns (uint) {
        return totalRaised;
    }

    function owner() public returns (address) {
        return OWNER;
    }

    function registerBeneficiary(address _user, uint percentage) public isOwner() {
        fundBeneficiaries.push(
            Beneficiary({
                beneficiary: _user,
                percentage: percentage
                }) // use array, so can iterate
            );
        );
    }

    function investments(address user) public returns (uint) {
        for(uint i = 0; i < contributions.length; i++){
            if(contributions[i].contributor == user)
                return contributions[i].amount;
        }
        return 0;
    }

    function performInvestment() public inState(State.Fundraising) payable returns (uint256) {
        contributions.push(
            Contribution({
                amount: msg.value,
                contributor: msg.sender
                }) // use array, so can iterate
            );
        totalRaised += msg.value;
        currentBalance = totalRaised;
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);

        checkIfFundingCompleteOrExpired();
        return contributions.length - 1; // return id
    }

    function checkIfFundingCompleteOrExpired() private {
        if (totalRaised > raiseTarget) {
            state = State.Successful;

        // could incentivize sender who initiated state change here
        } else if ( now > _endTime )  {
            state = State.ExpiredRefund; // backers can now collect refunds by calling getRefund(id)
        }
        completeAt = now;
    }

    function forwardFunds() payable public inState(State.Successful){
        for(uint i = 0; i < fundBeneficiaries.length; i++){
            beneficiary = fundBeneficiaries[i];
            if(!beneficiary.beneficiary.send(this.balance * 100 / beneficiary.percentage)) {
                revert();
            }
        }
        state = State.Closed;
        currentBalance = 0;
        emit LogWinnersPaid(fundBeneficiaries);
    }

    function transferOwnership(address owner) public isOwner() {
        OWNER = owner;
    }

    function getRefund(uint256 id) public inState(State.ExpiredRefund) returns (bool) {
        if (contributions.length <= id || id < 0 || contributions[id].amount == 0 ) {
            revert();
        }

        uint amountToRefund = contributions[id].amount;
        contributions[id].amount = 0;

        if(!contributions[id].contributor.send(amountToRefund)) {
            contributions[id].amount = amountToRefund;
            return false;
        }
        else{
            totalRaised -= amountToRefund;
            currentBalance = totalRaised;
        }

        return true;
    }

    function removeContract() public isOwner() atEndOfLifecycle() {
        selfdestruct(msg.sender);
        // OWNER gets all money that hasn't be claimed
    }

    function() public payable {
        revert();
    }
}