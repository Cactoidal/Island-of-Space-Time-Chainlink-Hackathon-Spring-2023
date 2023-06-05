// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//current deployment: 0xA1BecEaFeCd49F78804F20724B0e5c648f108faD

import "@openzeppelin/contracts/access/Ownable.sol";

contract SxTRelay is Ownable {

    string token;
    uint recentSet;
    mapping (address => bool) allowedSenders;

    function addRelay(address relay) public onlyOwner {
        allowedSenders[relay] = true;
    }

    function setToken(string memory _token) public {
        require(allowedSenders[msg.sender] == true);
        token = _token;
        recentSet = block.timestamp;
    }

    function checkOperational() public view returns (string memory) {
        if (block.timestamp > recentSet + 900) {
            return "false";
        }
        else {
            return "true";
        }
    }

    function getToken() public view returns (string memory) {
        return token;
    }
 
}
