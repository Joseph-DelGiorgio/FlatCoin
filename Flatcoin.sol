// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // Import Chainlink AggregatorV3Interface

contract Flatcoin is ERC20, Ownable {
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

    constructor(
        uint256 _initialSupply,
        uint256 _initialCollateralRatio,
        address _priceFeedAddress
    ) ERC20("Flatcoin", "FLAT") {
        _mint(msg.sender, _initialSupply * (10**uint256(decimals())));
        collateralRatio = _initialCollateralRatio;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // Update the price feed address if needed
    function setPriceFeed(address _newPriceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_newPriceFeed);
    }

    // Mint Flatcoins by locking up collateral
    function mint(uint256 _amount) external payable {
        uint256 requiredCollateral = (_amount * collateralRatio) / (10**uint256(decimals()));
        require(msg.value == requiredCollateral, "Incorrect collateral amount");

        totalCollateral += msg.value;
        totalSupply += _amount;
        _mint(msg.sender, _amount);
    }

    // Redeem Flatcoins for collateral
    function redeem(uint256 _amount) external {
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

    // Fallback function to accept collateral
    receive() external payable {}

    // Implement governance features, interest rates, and other functionalities as needed
}
