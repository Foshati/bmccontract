// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BuyMeACoffee {
    struct coffee {
        address sender;
        string message;
        uint256 timestamp;
    }
    uint256 totalCoffees;
    address public owner;

    event NewCoffee(address indexed sender, string message, uint256 timestamp);

    constructor() {
        owner = payable(msg.sender);
    }
    function buyMeACoffee(string memory _message) public payable {
        require(msg.value >= 0, "value must be greater than 0");
        totalCoffees += 1;
        payable(owner).transfer(msg.value);
        emit NewCoffee(msg.sender, _message, block.timestamp);
    }
    function getTotalCoffees() public view returns (uint256) {
        return totalCoffees;
    }
}
