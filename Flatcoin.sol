// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Flatcoin is ERC20, Ownable, Pausable, VRFConsumerBase {
    uint256 public collateralRatio; // Ratio of collateral required for minting (e.g., 200%)
    uint256 public totalCollateral; // Total collateral locked in the contract
    uint256 public totalSupply; // Total Flatcoins in circulation

    // Struct to represent a good in the basket
    struct Good {
        string name;
        uint256 weight;
    }

    Good[] public basketOfGoods; // Basket of goods used for cost of living calculation
    uint256 public costOfLiving; // Cost of living value based on the basket

    AggregatorV3Interface internal priceFeed; // Chainlink price feed interface

    uint256 public interestRate; // Annual interest rate for collateral
    mapping(address => uint256) public collateralBalances;
    
    bytes32 internal requestID;

    constructor(
        uint256 _initialSupply,
        uint256 _initialCollateralRatio,
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link
    ) ERC20("Flatcoin", "FLAT") VRFConsumerBase(_vrfCoordinator, _link) {
        _mint(msg.sender, _initialSupply * (10**uint256(decimals())));
        collateralRatio = _initialCollateralRatio;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        interestRate = 5; // 5% annual interest rate (can be adjusted)
    }

    // Update the price feed address if needed
    function setPriceFeed(address _newPriceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_newPriceFeed);
    }

    // Mint Flatcoins by locking up collateral
    function mint(uint256 _amount) external payable whenNotPaused {
        uint256 requiredCollateral = (_amount * collateralRatio) / (10**uint256(decimals()));
        require(msg.value == requiredCollateral, "Incorrect collateral amount");

        totalCollateral += msg.value;
        totalSupply += _amount;
        _mint(msg.sender, _amount);
    }

    // Redeem Flatcoins for collateral
    function redeem(uint256 _amount) external whenNotPaused {
        require(balanceOf(msg.sender) >= _amount, "Insufficient Flatcoins");
        require(totalSupply >= _amount, "Not enough Flatcoins in circulation");

        uint256 collateralAmount = (_amount * totalCollateral) / totalSupply;
        totalCollateral -= collateralAmount;
        totalSupply -= _amount;

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(collateralAmount);
    }

    // Owner can change the collateral ratio
    function setCollateralRatio(uint256 _newCollateralRatio) external onlyOwner {
        collateralRatio = _newCollateralRatio;
    }

    // Owner can add a good to the basket of goods
    function addGoodToBasket(string memory _name, uint256 _weight) external onlyOwner {
        basketOfGoods.push(Good({
            name: _name,
            weight: _weight
        }));
        _recalculateCostOfLiving();
    }

    // Owner can adjust the weight of a good in the basket
    function adjustGoodWeight(uint256 _index, uint256 _newWeight) external onlyOwner {
        require(_index < basketOfGoods.length, "Good index out of bounds");
        basketOfGoods[_index].weight = _newWeight;
        _recalculateCostOfLiving();
    }

    // Calculate the cost of living based on the basket of goods using Chainlink price feed
    function _recalculateCostOfLiving() internal {
        uint256 newCostOfLiving = 0;
        for (uint256 i = 0; i < basketOfGoods.length; i++) {
            (, int256 price, , , ) = priceFeed.latestRoundData();
            require(price > 0, "Invalid price data");
            newCostOfLiving += (basketOfGoods[i].weight * uint256(price)) / 1e8; // Adjust the divisor as needed
        }
        costOfLiving = newCostOfLiving;
    }

    // Pause and unpause the contract in case of emergency
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Implement interest calculations for collateral
    function calculateInterest(address _user) internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - collateralBalances[_user];
        return (collateralBalances[_user] * interestRate * elapsedTime) / (365 days * 100);
    }

    // Deposit and withdraw collateral with interest
    function depositCollateral() external payable {
        collateralBalances[msg.sender] += msg.value;
    }

    function withdrawCollateral(uint256 _amount) external {
        require(collateralBalances[msg.sender] >= _amount, "Insufficient collateral");
        uint256 interest = calculateInterest(msg.sender);
        collateralBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount + interest);
    }

    // Chainlink VRF related functions
    function requestRandomNumber() external onlyOwner returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Not enough LINK tokens");
        requestID = requestRandomness(keyHash, chainlinkFee);
        return requestID;
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber) internal override {
        // Use the random number as needed in your contract
        // For example, you can implement random events or decisions
    }
}
