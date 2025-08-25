pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    uint256 public constant tokensPerEth = 100;

    YourToken public yourToken;

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    // ToDo: create a payable buyTokens() function:
    function buyTokens() public payable {
        require(msg.sender != address(0), "Should be a valid address");
        require(msg.value > 0, "Payment should be not zero");

        uint256 tokenCount = tokensPerEth * msg.value;

        // This will auto fail if not enough token available
        yourToken.transfer(msg.sender, tokenCount);

        emit BuyTokens(msg.sender, msg.value, tokenCount);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() public {
        require(msg.sender == owner(), "Only owner can withdraw");
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdrawal failed, please try again");
    }

    // ToDo: create a sellTokens(uint256 _amount) function:
    function sellTokens(uint256 _amount) public {
        // Check if sender has enough token to sell
        require(yourToken.balanceOf(msg.sender) >= _amount, "You don't enough token sell");

        // Check if sender has approved enough token to Vendor
        require(yourToken.allowance(msg.sender, address(this)) >= _amount, "Not enought token authorized the sell");

        uint256 ethAmount = _amount / tokensPerEth;

        // Vendor should have fund to perform this sell operation
        require(address(this).balance >= ethAmount, "Sorry, we don't have eth for this sell, please try in some time");

        yourToken.transferFrom(msg.sender, address(this), _amount);
        (bool success, ) = msg.sender.call{ value: ethAmount }("");

        // Sending of fund should successed
        require(success, "Sell failed, please try again");

        emit SellTokens(msg.sender, _amount, ethAmount);
    }
}
