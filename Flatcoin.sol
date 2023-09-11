// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

    constructor(uint256 _initialSupply, uint256 _initialCollateralRatio) ERC20("Flatcoin", "FLAT") {
        _mint(msg.sender, _initialSupply * (10 ** uint256(decimals())));
        collateralRatio = _initialCollateralRatio;
    }

    // Mint Flatcoins by locking up collateral
    function mint(uint256 _amount) external payable {
        require(msg.value == (_amount * collateralRatio), "Incorrect collateral amount");

        totalCollateral += msg.value;
        totalSupply += _amount;
        _mint(msg.sender, _amount * (10 ** uint256(decimals())));
    }

    // Redeem Flatcoins for collateral
    function redeem(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Insufficient Flatcoins");
        require(totalSupply >= _amount, "Not enough Flatcoins in circulation");

        uint256 collateralAmount = (_amount * msg.value) / totalSupply;
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

    // Import the Chainlink AggregatorV3Interface contract
      AggregatorV3Interface internal priceFeed;

  // Constructor to set the initial price feed address (you can change it later)
    constructor(uint256 _initialSupply, uint256 _initialCollateralRatio, address _priceFeedAddress)
    ERC20("Flatcoin", "FLAT")
    {
        _mint(msg.sender, _initialSupply * (10 ** uint256(decimals())));
        collateralRatio = _initialCollateralRatio;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // Update the price feed address if needed
      function setPriceFeed(address _newPriceFeed) external onlyOwner {
        priceFeed = AggregatorV3Interface(_newPriceFeed);
    }

    // Updated _recalculateCostOfLiving to fetch data from Chainlink
      function _recalculateCostOfLiving() internal {
        uint256 newCostOfLiving = 0;
        for (uint256 i = 0; i < basketOfGoods.length; i++) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price data");
        newCostOfLiving += (basketOfGoods[i].weight * uint256(price)) / 1e18; // Adjust the divisor as needed
    }
      costOfLiving = newCostOfLiving;
}

    // Replace this with a real price oracle or data source
    

    // Fallback function to accept collateral
    receive() external payable {}

    // Implement governance features, interest rates, and other functionalities as needed
}
