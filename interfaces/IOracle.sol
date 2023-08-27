// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOracle {
    function decimals() external view returns (uint256);

    function setProductPrice( 
        uint256 productId, 
        uint256 newProductPrice
        ) 
        external;

    function getProductPriceById(uint256 productId) 
        external view 
        returns(uint256);
}
