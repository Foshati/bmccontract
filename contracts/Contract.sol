// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title BuyMeACoffee - Enhanced Version
 * @author Your Name
 * @notice A smart contract that allows people to buy coffee for the owner and leave messages
 * @dev Implements coffee purchasing with messages, withdrawal functionality, and coffee history
 */
contract BuyMeACoffee {
    // Custom errors (gas efficient)
    error InsufficientPayment();
    error NotOwner();
    error WithdrawalFailed();
    error EmptyMessage();

    // Coffee structure
    struct Coffee {
        address sender;
        string message;
        uint256 amount;
        uint256 timestamp;
    }

    // State variables
    uint256 public totalCoffees;
    uint256 public totalAmount;
    address public immutable owner;
    
    // Mapping to store all coffees
    mapping(uint256 => Coffee) public coffees;
    
    // Mapping to track user's total contributions
    mapping(address => uint256) public userContributions;

    // Events
    event NewCoffee(
        address indexed sender, 
        string message, 
        uint256 amount,
        uint256 timestamp,
        uint256 coffeeId
    );
    
    event Withdrawal(address indexed owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier validPayment() {
        if (msg.value == 0) revert InsufficientPayment();
        _;
    }

    modifier nonEmptyMessage(string memory _message) {
        if (bytes(_message).length == 0) revert EmptyMessage();
        _;
    }

    /**
     * @notice Constructor sets the contract deployer as owner
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Buy a coffee with a message
     * @param _message The message to include with the coffee purchase
     */
    function buyMeACoffee(string memory _message) 
        external 
        payable 
        validPayment 
        nonEmptyMessage(_message) 
    {
        uint256 coffeeId = totalCoffees;
        
        // Store coffee details
        coffees[coffeeId] = Coffee({
            sender: msg.sender,
            message: _message,
            amount: msg.value,
            timestamp: block.timestamp
        });

        // Update state
        totalCoffees++;
        totalAmount += msg.value;
        userContributions[msg.sender] += msg.value;

        // Emit event
        emit NewCoffee(msg.sender, _message, msg.value, block.timestamp, coffeeId);
    }

    /**
     * @notice Get details of a specific coffee by ID
     * @param _coffeeId The ID of the coffee to retrieve
     * @return Coffee struct containing all details
     */
    function getCoffee(uint256 _coffeeId) external view returns (Coffee memory) {
        require(_coffeeId < totalCoffees, "Coffee does not exist");
        return coffees[_coffeeId];
    }

    /**
     * @notice Get the latest N coffees
     * @param _count Number of recent coffees to retrieve
     * @return Array of Coffee structs
     */
    function getRecentCoffees(uint256 _count) external view returns (Coffee[] memory) {
        if (_count > totalCoffees) {
            _count = totalCoffees;
        }
        
        Coffee[] memory recentCoffees = new Coffee[](_count);
        
        for (uint256 i = 0; i < _count; i++) {
            recentCoffees[i] = coffees[totalCoffees - 1 - i];
        }
        
        return recentCoffees;
    }

    /**
     * @notice Get total number of coffees purchased
     * @return Total coffee count
     */
    function getTotalCoffees() external view returns (uint256) {
        return totalCoffees;
    }

    /**
     * @notice Get total amount collected
     * @return Total amount in wei
     */
    function getTotalAmount() external view returns (uint256) {
        return totalAmount;
    }

    /**
     * @notice Get contract balance
     * @return Current contract balance in wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get user's total contribution
     * @param _user Address of the user
     * @return Total contribution amount in wei
     */
    function getUserContribution(address _user) external view returns (uint256) {
        return userContributions[_user];
    }

    /**
     * @notice Withdraw all funds to owner (only owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = payable(owner).call{value: balance}("");
        if (!success) revert WithdrawalFailed();

        emit Withdrawal(owner, balance);
    }

    /**
     * @notice Withdraw specific amount to owner (only owner)
     * @param _amount Amount to withdraw in wei
     */
    function withdrawAmount(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient contract balance");
        require(_amount > 0, "Amount must be greater than 0");

        (bool success, ) = payable(owner).call{value: _amount}("");
        if (!success) revert WithdrawalFailed();

        emit Withdrawal(owner, _amount);
    }

    /**
     * @notice Emergency withdrawal function
     */
    function emergencyWithdraw() external onlyOwner {
        selfdestruct(payable(owner));
    }

    // Fallback function to accept direct transfers
    receive() external payable {
        totalAmount += msg.value;
        emit NewCoffee(msg.sender, "Direct transfer", msg.value, block.timestamp, totalCoffees);
    }
}