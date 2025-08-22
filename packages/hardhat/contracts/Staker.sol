// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    address[] stakers;
    uint public deadline = block.timestamp + 72 hours;
    uint public constant threshold = 1 ether;
    bool public openForWithdrawal = false;

    event Stake(address indexed staker, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    modifier beforeCompleted() {
        require(!exampleExternalContract.completed(), "Stake completed, Try next time");
        _;
    }

    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Deadline is not passed yet");
        _;
    }

    modifier beforeDedline() {
        require(block.timestamp < deadline, "Deadline is passed to stake");
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)

    function stake() public payable beforeDedline {
        require(msg.value > 0, "Must send some ether to stake");
        balances[msg.sender] += msg.value;
        stakers.push(msg.sender);
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    function execute() public afterDeadline beforeCompleted {
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{ value: address(this).balance }();
        }
        openForWithdrawal = true;
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public afterDeadline {
        require(address(this).balance < threshold, "Can't withdraw if staking thresold met !!");
        require(openForWithdrawal, "Withdrwal not open yet, execute first !!");

        uint256 amount = balances[msg.sender];
        address recepient = msg.sender;

        require(amount > 0, "Either you not staked or already withdrwal your fund");

        balances[recepient] = 0;
        (bool success, ) = recepient.call{ value: amount }("");
        require(success, "Withdrwal failed, please try again");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }

    fallback() external payable {
        stake();
    }

    function restartStacking() public afterDeadline {
        require(address(this).balance <= 0, "Existing fund should be withdrwan before restart");

        // Reset the deadline
        deadline = block.timestamp + 72 hours;
        openForWithdrawal = false;

        // reset stake balances
        for (uint index = 0; index < stakers.length; ) {
            address staker = stakers[index];
            balances[staker] = 0;

            unchecked {
                ++index;
            }
        }

        delete stakers;

        // Reset the example contract
        exampleExternalContract.reset();
    }
}
