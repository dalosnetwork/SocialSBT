// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SocialSBT is ERC721Enumerable, Ownable {
    uint256 private _price;
    uint256 private _votingTime;
    uint256 private _votingIndex;

    mapping(uint256 => uint256) private _pointOf;
    mapping(uint256 => Voting) private _votings;
    mapping(uint256 => mapping(address => bool)) private _isVoted;

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

    event NewVotingCreated(
        uint256 votingIndex,
        uint256 tokenIndex,
        uint256 point,
        bool increase
    );

    event VoteEvent(
        uint256 votingIndex,
        uint256 tokenIndex,
        bool choice
    );

    event VotingEnd(
        uint256 votingIndex,
        uint256 tokenIndex,
        uint256 point,
        bool increase
    );

    event PointUpdated(
        uint256 index,
        uint256 point,
        bool increase
    );

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 price_,
        uint256 votingTime_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        _price = price_;
        _votingTime = votingTime_;
    }

    function mint() public payable {
        require(msg.value == _price, "Incorrect payment amount");
        require(balanceOf(msg.sender) == 0, "Address already owns a token");

        uint256 tokenId = totalSupply();
        _safeMint(msg.sender, tokenId);
    }

    function deleteToken(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Only owner can delete token");

        _burn(tokenId);
    }

    function createVoting(
        string memory name_,
        string memory description_,
        uint256 tokenIndex_,
        uint256 point_,
        bool increase_
    ) public {
        require(ownerOf(tokenIndex_) == msg.sender, "Not the owner of token");

        Voting memory voting = Voting({
            votingIndex: _votingIndex,
            name: name_,
            description: description_,
            tokenIndex: tokenIndex_,
            point: point_,
            increase: increase_,
            yes: 0,
            no: 0,
            startDate: block.timestamp,
            endDate: block.timestamp + _votingTime,
            isActive: true
        });

        _votings[_votingIndex] = voting;

        emit NewVotingCreated(_votingIndex, tokenIndex_, point_, increase_);

        _votingIndex++;
    }

    function vote(uint256 votingIndex_, bool choice_) public {
        require(balanceOf(msg.sender) > 0, "You must own a token to vote");
        require(!_isVoted[votingIndex_][msg.sender], "Already voted");
        require(_votings[votingIndex_].isActive, "Voting is not active");

        Voting storage voting = _votings[votingIndex_];

        if (choice_) {
            voting.yes++;
        } else {
            voting.no++;
        }

        _isVoted[votingIndex_][msg.sender] = true;

        emit VoteEvent(votingIndex_, voting.tokenIndex, choice_);
    }

    function endVoting(uint256 votingIndex_) public {
        Voting storage voting = _votings[votingIndex_];
        require(block.timestamp >= voting.endDate, "Voting period not ended");

        if (voting.yes > voting.no) {
            if (voting.increase) {
                _pointOf[voting.tokenIndex] += voting.point;
            } else {
                _pointOf[voting.tokenIndex] -= voting.point;
            }

            emit PointUpdated(
                voting.tokenIndex,
                voting.point,
                voting.increase
            );
        }

        voting.isActive = false;

        emit VotingEnd(
            voting.votingIndex,
            voting.tokenIndex,
            voting.point,
            voting.increase
        );
    }

    function pointOf(uint256 tokenId) public view returns (uint256) {
        return _pointOf[tokenId];
    }

    function isVotingActive(uint256 votingIndex_) public view returns (bool) {
        return _votings[votingIndex_].isActive;
    }

    function isVoted(uint256 votingIndex_, address voter) public view returns (bool) {
        return _isVoted[votingIndex_][voter];
    }

    function votingDetails(uint256 votingIndex_)
        public
        view
        returns (Voting memory)
    {
        return _votings[votingIndex_];
    }
}
