// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IOracle.sol";

/* 
 * Для каждой страны свой
 * К нему обращается токен торговой пары для получения рейта
 */
contract Oracle is IOracle, Ownable {
    mapping(uint256 => uint256) private _productPrice;

    event PriceChange(uint256 indexed productId, uint256 oldPrice, uint256 newPrice);

    constructor(
        address system, 
        uint256[] memory resourceIds,  
        uint256[] memory prices
    ) Ownable() {
        if(system != owner()) {
            transferOwnership(system);
        }

        uint256 productsLen = resourceIds.length;
        require(productsLen != 0, "TToken: zero length of price array for nomenclature of products");
        require(productsLen == prices.length, "TToken: length of resourceIds and price arrays must be equal");

        uint256 i;
        for(i; i<productsLen; i++) {
            uint256 resourceId = resourceIds[i];
            require(
                prices[i] != 0, 
                "Oracle: price for product in nomenclature mustn'be zero"
            );
            _productPrice[resourceId] = prices[i];
        }
    }

    function setProductPrice(
        uint256 productId, 
        uint256 newProductPrice
    ) 
        public 
        onlyOwner 
    {
        uint256 price = _productPrice[productId];
        require(price != 0, "Oracle: unappropriate productId");
        
        _productPrice[productId] = newProductPrice;
        emit PriceChange(productId, price, newProductPrice);
    }

    // Fixed number for mvp
    function decimals() external pure returns(uint256) {
        return 1;
    }

    function getProductPriceById(uint256 productId) external view returns(uint256) {
       uint256 price = _productPrice[productId];
       require(price != 0, "Oracle: unappropriate productId");
       
       return price;
    }
}