// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "https://github.com/dalosnetwork/SocialSBT/blob/main/contracts/SocialSBT.sol";

contract SocialSBTFactory {

    event newSBTCreated(string name_, string symbol_, uint256 price_, uint256 votingTime_, address SBTAddress);

    function createNewSocialSBT(string memory name_, string memory symbol_, uint256 price_, uint256 votingTime_) public returns(address) {
        SocialSBT newSocialSBT = new SocialSBT(name_, symbol_, price_, votingTime_);

        address addressOfSBT = address(newSocialSBT);

        emit newSBTCreated(name_, symbol_, price_, votingTime_, addressOfSBT);

        return addressOfSBT;
    }
}
