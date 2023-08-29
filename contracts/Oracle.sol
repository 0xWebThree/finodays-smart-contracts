// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IOracle.sol";

/* 
 * Для каждой страны свой
 * К нему обращается токен торговой пары для получения рейта
 */
contract Oracle is IOracle, Ownable {
    // больше как лимиты. для того, чтобы другие расплачивались другими курсами
    // а не только золотом 
    mapping(uint256 => uint256) private _productRate;

    event RateChange(uint256 indexed productId, uint256 oldRate, uint256 newRate);

    constructor(
        address system, 
        uint256[] memory resourceIds,  
        uint256[] memory rates
    ) Ownable() {
        if(system != owner()) {
            transferOwnership(system);
        }

        uint256 productsLen = resourceIds.length;
        require(productsLen != 0, "TToken: zero length of Rate array for nomenclature of products");
        require(productsLen == rates.length, "TToken: length of resourceIds and Rate arrays must be equal");

        uint256 i;
        for(i; i<productsLen; i++) {
            uint256 resourceId = resourceIds[i];
            require(
                rates[i] != 0, 
                "Oracle: Rate for product in nomenclature mustn'be zero"
            );
            _productRate[resourceId] = rates[i];
        }
    }

    function setProductRate(
        uint256 productId, 
        uint256 newProductRate
    ) 
        public 
        onlyOwner 
    {
        uint256 rate = _productRate[productId];
        require(rate != 0, "Oracle: unappropriate productId");
        
        _productRate[productId] = newProductRate;
        emit RateChange(productId, rate, newProductRate);
    }

    // Fixed number for mvp,
    // работает вместе с рейтом в паре
    function decimals() external pure returns(uint256) {
        return 1;
    }

    function getProductRateById(uint256 productId) external view returns(uint256) {
       uint256 rate = _productRate[productId];
       require(rate != 0, "Oracle: unappropriate productId");
       
       return rate;
    }
}