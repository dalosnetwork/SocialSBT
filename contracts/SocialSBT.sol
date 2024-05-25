// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SocialSBT {
    uint256 private _index;
    uint256 private _price;
    uint256 private _votingIndex;
    uint256 private _votingTime;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _ownerOf;
    mapping(address => bool) private _isOwned;
    mapping(uint256 => uint256) private _pointOf;
    mapping(uint256 => Voting) private _votings;
    mapping(uint256 => mapping(address => bool)) _isVoted;

    constructor(string memory name_, string memory symbol_, uint256 price_, uint256 votingTime_){
        _name = name_;
        _symbol = symbol_;
        _price = price_;
        _votingTime = votingTime_;
    }

    struct Voting {
        uint256 votingIndex;
        string name;
        string description;
        uint256 tokenIndex;
        uint256 point;
        bool increase;
        uint256 yes;
        uint256 no;
        uint256 startDate;
        uint256 endDate;
        bool isActive;
    }

    event newVotingCreated(
        uint256 votingIndex,
        uint256 tokenIndex,
        uint256 point,
        bool increase
    );

    event voteEvent(
        uint256 votingIndex,
        uint256 tokenIndex,
        bool choice
    );

    event votingEnd(
        uint256 votingIndex,
        uint256 tokenIndex,
        uint256 point,
        bool increase
    );

    event point(
        uint256 index,
        uint256 point,
        bool increase
    );

    function vote(uint256 votingIndex_, bool choice_) public returns (bool) {
        require(isOwned(msg.sender));
        require(!isVoted(votingIndex_, msg.sender));
        require(isVotingActive(votingIndex_));

        Voting storage _voting = _votings[votingIndex_];

        if (choice_) {
            _voting.yes++;
        } else {
            _voting.no++;
        }

        voted(votingIndex_);

        emit voteEvent(votingIndex_, _voting.tokenIndex, choice_);

        return true;
    }

    function isVotingActive(uint256 votingIndex_) public view returns (bool) {
        Voting memory _voting = votings(votingIndex_);

        return _voting.isActive;
    }

    function endVoting(uint256 votingIndex_) public returns (bool) {
        Voting storage _voting = _votings[votingIndex_];
        require(_voting.endDate > block.timestamp);

        if (_voting.yes > _voting.no) {
            if (_voting.increase) {
                increasePoint(_voting.tokenIndex, _voting.point);
            } else {
                decreasePoint(_voting.tokenIndex, _voting.point);
            }
        }

        _voting.isActive = false;

        emit votingEnd(votingIndex_, _voting.tokenIndex, _voting.point,
        _voting.increase);

        return true;
    }

    function increasePoint(uint256 index_, uint256 point_) internal {
        _pointOf[index_] += point_;

        emit point(index_, point_, false);
    }

    function decreasePoint(uint256 index_, uint256 point_) internal {
        _pointOf[index_] -= point_;

        emit point(index_, point_, false);
    }

    function createIncreasingVoting(
        string memory name_,
        string memory description_,
        uint256 tokenIndex_,
        uint256 point_
    ) public returns (bool) {
        require(isOwned(msg.sender));
        
        Voting memory _voting = Voting({
            votingIndex: votingIndex(),
            name: name_,
            description: description_,
            tokenIndex: tokenIndex_,
            point: point_,
            increase: true,
            yes: 0,
            no: 0,
            startDate: block.timestamp,
            endDate: block.timestamp + votingTime(),
            isActive: true
        });

        addToVotings(_voting, votingIndex());        

        emit newVotingCreated(votingIndex(), tokenIndex_, point_, true);


        increaseVotingIndex();

        return true;
    }

    function createDecreasingVoting(
        string memory name_,
        string memory description_,
        uint256 tokenIndex_,
        uint256 point_
    ) public returns (bool) {
        require(isOwned(msg.sender));

        Voting memory _voting = Voting({
            votingIndex: votingIndex(),
            name: name_,
            description: description_,
            tokenIndex: tokenIndex_,
            point: point_,
            increase: false,
            yes: 0,
            no: 0,
            startDate: block.timestamp,
            endDate: block.timestamp + votingTime(),
            isActive: true
        });

        addToVotings(_voting, votingIndex());
        
        emit newVotingCreated(votingIndex(), tokenIndex_, point_, false);
                
        increaseVotingIndex();
        
        return true;
    }

    function votings(uint256 votingIndex_) public view returns (Voting memory) {
        return _votings[votingIndex_];
    }

    function isVoted(uint256 votingIndex_, address voterAddress_) public view returns (bool) {
        return _isVoted[votingIndex_][voterAddress_];
    }

    function voted(uint256 votingIndex_) public returns (bool) {
        _isVoted[votingIndex_][msg.sender] = true;

        return true;
    }

    function pointOf(uint256 index_) public view returns (uint256) {
        return _pointOf[index_];
    }

    function ownerOf(uint256 index_) public view returns (address) {
        require(index_ <= _index);
        return _ownerOf[index_];
    }

    function isOwned(address owner_) public view returns (bool) {
        return _isOwned[owner_];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function votingTime() public view returns (uint256) {
        return _votingTime;
    }

    function index() public view returns (uint256) {
        return _index;
    }

    function votingIndex() public view returns (uint256) {
        return _votingIndex;
    }

    function mint() public payable returns (bool) {
        require(msg.value == price());
        require(!isOwned(msg.sender));

        addNewOwner();
        updateIsOwned(true);

        increaseIndex();

        return true;

    }

    function deleteToken(uint256 index_) public returns (bool) {
        require(ownerOf(index_) == msg.sender);

        removeOwner(index_);
        updateIsOwned(false);
        payable(msg.sender).transfer(price());

        return true;
    }

    function addToVotings(Voting memory voting_, uint256 votingIndex_) internal {
        _votings[votingIndex_] = voting_;
    }

    function addNewOwner() internal {
        _ownerOf[_index] = msg.sender;
    }

    function removeOwner(uint256 index_) internal {
        _ownerOf[index_] = address(0x0);
    }

    function updateIsOwned(bool isOwned_) internal {
        _isOwned[msg.sender] = isOwned_;
    }

    function increaseIndex() internal {
        _index++;
    }

    function increaseVotingIndex() internal {
        _votingIndex++;
    }

}
