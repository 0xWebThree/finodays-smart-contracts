// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./../interfaces/IOracle.sol";

/*
Создание торговых токенов
Фабрика смартов(добавление других компаний [регистрация компании(по коду компании), его токена])


по кажд стране
приобрет за валюту

fix цена (изменение через оракул будет, через функцию)
getPrice() из смарта оракула, получаем рейт (грубо говоря) => минтим в соотв с рейтом

страна мож создавать свои товары, ордер
*/

// товарный токен
contract TToken is ERC20 {
    // ISO code: http://www.davros.org/misc/iso3166.html
    uint256 immutable private _countryCode;
    
    struct Product {
        uint256 price;
        uint256 balance;
    }
    mapping(uint256 => Product) _countryNomenclature;
    uint256 private _totalProductsInNomenclature;

    IOracle immutable internal _productOracle;
    address immutable internal _factory;

    enum Status { InProgress, Completed }
    struct Operation {
        uint256 fromCompany;
        uint256 toCompany;
        uint256 operationCode;
        Status status;
        uint256 subjectCode;  // code of country product || company's product(like TVs)
        uint256 subjectAmount;
        uint256 ttokensAmount;
        uint256 timestamp;
    }
    mapping(uint256 => Operation) private _operations;
    
    struct Company {
       string name;
       address mainAddress;
    }
    // Company code => Company info
    mapping(uint256 => Company) private _company;
    uint256 private _totalCompanies;

    constructor(
        string memory name, 
        string memory symbol,
        uint256 countryCode,
        address productOracle,
        address factory,
        uint256[] memory prices,
        uint256[] memory balances
    ) ERC20(name, symbol) {
        require(countryCode != 0, "TToken: There is no country with zero code");
        require(productOracle != address(0), "TToken: Oracle address must be initialized");
        require(factory != address(0), "TToken: Factory address must be initialized");
        
        uint256 productsLen = prices.length;
        require(productsLen != 0, "TToken: zero length of price array for nomenclature of products");
        require(productsLen == balances.length, "TToken: length of balance and price arrays must be equal");

        _countryCode = countryCode;
        _productOracle = IOracle(productOracle);
        _factory = factory;
        uint256 i;
        for(i; i<productsLen; i++) {
            require(
                prices[i] != 0, 
                "TToken: price for product in nomenclature mustn'be zero"
            );
            require(
                balances[i] != 0, 
                "TToken: balance for product in nomenclature mustn'be zero"
            );
            _countryNomenclature[i] = Product(prices[i], balances[i]);
        }
        _totalProductsInNomenclature = productsLen;
    }

    function addCompany(string calldata name) external {
        _company[_totalCompanies] = Company(name, _msgSender());
        ++ _totalCompanies;
    }

    function setOperationAsComplete() external {

    }

    function getProductPrice(uint256 productId) 
        public view 
        returns (uint256) 
    {
        return _productOracle.getProductPrice(productId);
    }

    function burn(uint256 amount) external {
        super._burn(_msgSender(), amount);
    }

    function getCountryCode() public view returns(uint256) {
        return _countryCode;
    }
    function getFactoryAddress() public view returns(address) {
        return _factory;
    }
    function getOracleAddress() public view returns(address) {
        return address(_productOracle);
    }
}