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

    constructor(address system) Ownable() {
        if(system != owner()) {
            transferOwnership(system);
        }
    }

    function setProductPrice(
        uint256 productId, 
        uint256 newProductPrice
    ) 
        external 
        onlyOwner 
    {
        _productPrice[productId] = newProductPrice;
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