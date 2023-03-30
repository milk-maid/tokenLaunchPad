// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract LaunchPad {

    struct {
        address creator;
        uint goal;
        uint pledged;
        uint startAt;
        uint endAt;
        bool claimed
    }

    // supported token
    IERC20 public immutable token;

    // campaign unique id
    uint public count;

    // mapping campaign ID 
    mapping(uint => Campaign) public campaigns;

    // ID to user address to amountpledged
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    event Launch(uint id, address indexed creator, uint target, uint startTime, uint endTime);
    event Cancel(uint id);
    event Pledge(uint id, address indexed caller, uint amount);
    event Unpledge(uint id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount)
    
    function launch(uint _goal, uint _startAt, uint _endAt) external {
        require(_startAt >= block.timestamp, "starting time not feasible");
        require(_endAt >= _startAt, "stopping time not visible";);
        require(_endAt <= block.timestamp + 10 days, "stppping time not allowed");

        count += 1;
        campaign[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        })

        emit Launch(count, msg.sender, _goal, _startAt, _endAt)
    }

    function cancel(uint _id) external{
        Campaign memory campaign = campaigns[id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp < campaign.startAt, "started");
        delete campaigns[id];

        emit Cancel(_id);
    }

    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaign[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp < campaign.endAt, "ended");

        campaign.pledge += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaign[_id];
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledge -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        Campaign storage campaign = campaign[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp > campaign.endAt, "ended");
        require(campaign.pledged >= campaign.goal, "pledge less than goal");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        tokwn.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);


    }

    function refund(uint _id) external {
        Campaign storage campaign = campaign[_id];
        require(block.timestamp > campaign.endAt, "ended");
        require(campaign.pledged < campaign.goal, "pledge less than goal");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);

    }

    function adminThis() external {}
}
