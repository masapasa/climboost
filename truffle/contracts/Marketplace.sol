// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./CarbonCredit.sol";
contract MarketPlace {
    CarbonCredit carbonCredit;
    address public marketplaceOwner;
    struct listing {
        uint firmId;
        uint qty;
        bool isValue;
    }
    mapping(uint => listing) public creditsForSale;
    uint[] public prices;
    uint[] public qty;
    uint numListings = 0;
    uint lastNumFilled;
    uint lastAvgPriceFilled;
    constructor(CarbonCredit carbonCredit_address){
        carbonCredit = carbonCredit_address;
        marketplaceOwner = msg.sender;
    }
    modifier onlyConsumer(uint firmId) {
        require(carbonCredit.isConsumer(firmId));
        _;
    }
    modifier onlyGenerator(uint firmId) {
        require(carbonCredit.isGenerator(firmId));
        _;
    }
    function getPrices() public view returns (uint[] memory) {
        return prices;
    }
    function getQty() public view returns (uint[] memory) {
        return qty;
    }
    function getNumListings() public view returns (uint) {
        return numListings;
    }
    function getMinIdx(uint[] memory price) public view returns (uint) {
        uint minValue = 1000000;
        uint minIdx;
        for (uint i = 0; i < numListings; i++) {
            if (price[i] > 0 && price[i] < minValue) {
                minValue = prices[i];
                minIdx = i;
            }
        }
        return minIdx;
    }
    function getLastNumFilled() public view returns (uint) {
        return lastNumFilled;
    }
    function getLastAvgPriceFilled() public view returns (uint) {
        return lastAvgPriceFilled;
    }
    function listCredit(uint firmId, uint price, uint quantity) public {
        bool consumer;
        if (carbonCredit.isConsumer(firmId)) {
            consumer = true;
            assert(carbonCredit.getConsumerCredits(firmId) >= quantity);
        } else if (carbonCredit.isGenerator(firmId)) {
            consumer = false;
            assert(carbonCredit.getGeneratorCredits(firmId) >= quantity);
        }
        assert(price > 0);
        require(creditsForSale[price].isValue == false, "this price is already listed. Please go one up or one down.");
        listing memory newListing = listing(firmId, quantity, true);
        creditsForSale[price] = newListing;
        prices.push(price);
        qty.push(quantity);
        numListings += 1;
        carbonCredit.transferFrom(msg.sender, marketplaceOwner, quantity);
        if (consumer) {
            carbonCredit.updateConsumerBalance(firmId, quantity, true);
        } else {
            carbonCredit.updateGeneratorBalance(firmId, quantity, true);
        }
    }
    function buyCredit(uint buyer, uint quantity) public onlyConsumer(buyer) returns (uint numFilled, uint avgPriceFilled) {
        assert(quantity > 0);
        uint filled = 0;
        uint totalPaid = 0;
        while (filled < quantity) {
            if (numListings == 0) {
                carbonCredit.transferFrom(marketplaceOwner, msg.sender, quantity);
                carbonCredit.updateConsumerBalance(buyer, filled, false);
                if (filled == 0) {
                    lastNumFilled = 0;
                    lastAvgPriceFilled = 0;
                    return (filled, 0);
                }
                else {
                    lastNumFilled = filled;
                    lastAvgPriceFilled = totalPaid / filled;
                    return (filled, totalPaid / filled);
                }
            }
            uint minIdx = getMinIdx(prices);
            uint currPrice = prices[minIdx];
            uint currQty = qty[minIdx];
            uint yetToFill = quantity - filled;
            if (currQty > yetToFill) {
                filled += yetToFill;
                totalPaid += yetToFill * currPrice;
                creditsForSale[currPrice].qty -= yetToFill;
                qty[minIdx] -= yetToFill;
            }
            else if (currQty <= yetToFill) {
                filled += currQty;
                totalPaid += currPrice * currQty;
                delete prices[minIdx];
                delete qty[minIdx];
                numListings -= 1;
                prices[minIdx] = prices[numListings];
                qty[minIdx] = qty[numListings];
                prices.pop();
                qty.pop();
                delete creditsForSale[currPrice];
            }
        }
        carbonCredit.transferFrom(marketplaceOwner, msg.sender, quantity);
        carbonCredit.updateConsumerBalance(buyer, filled, false);
        lastNumFilled = filled;
        lastAvgPriceFilled = totalPaid / filled;
        return (filled, totalPaid / filled);
    }
}