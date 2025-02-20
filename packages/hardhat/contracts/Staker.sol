// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    uint256 public deadline;
    bool public openForWithdraw = false;
    mapping ( address => uint256 ) public balances; 
    uint256 public constant threshold = 1 ether;
    mapping(address => bool) public isStaker; // Track active stakers

    // Event to log staking actions
    event Stake(address indexed staker, uint256 amount);
    event Withdraw(address indexed staker, uint256 amount);


    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "contract already completed!");
        _;
    }

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
        deadline = block.timestamp + 72 * 60 * 60; // 72 hours
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
    function stake() public payable {
        require(block.timestamp < deadline, "staking period is over");
        require(msg.value  > 0, "amount must be greater than 0");

        if (balances[msg.sender] == 0) {
            isStaker[msg.sender] = true;
        }

        // update the staked amount for the user
        balances[msg.sender] += msg.value ;

        // emit an event for the staking action (optional)
        emit Stake(msg.sender, msg.value);
        console.log("balance: ", address(this).balance);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    function execute() public notCompleted {
        console.log("block.timestamp >= deadline: ", block.timestamp >= deadline);
        require(block.timestamp >= deadline, "Deadline has not passed yet");

        if (address(this).balance >= threshold) {
            // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
            exampleExternalContract.complete{value: address(this).balance}();
            openForWithdraw = false;
            console.log("threshold exceeded, openForWithdraw: ", openForWithdraw);
        } else { 
            openForWithdraw = true;
            console.log("threshold not exceeded, openForWithdraw: ", openForWithdraw);
        }
    }

    // openForWithdraw bool to true should allow users to withdraw() their funds
    function withdraw() public {
        require(openForWithdraw, "withdrawals are not allowed yet");
        uint256 amount = balances[msg.sender];
        require(amount > 0, "no balance to withdraw");

        // reset balance before transfer to prevent reentrancy attacks
        balances[msg.sender] = 0;
        isStaker[msg.sender] = false; // Mark staker as removed
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp; 
    }
}
