// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./../interfaces/IOracle.sol";

/*
Смарт-контракт торгового токена, создается фабрикой
*/

// Товарный токен
contract TToken is ERC20 {
    // ISO code: http://www.davros.org/misc/iso3166.html
    uint256 immutable private _countryCode;
    
    // код биржевого товара => balance
    mapping(uint256 => uint256) _nomenclatureResources;
    uint256 private _totalProductsInNomenclature;

    IOracle immutable internal _productOracle;
    address immutable internal _factory;

    enum OperationCode { TopUp, Transfer, Swap, Withdraw }
    /*
     * all operation statuses will be 'Completed' in MVP
     * as if the verification oracle has worked
     */
    enum OperationStatus {Created, InProgress, Completed }
    struct Operation {
        uint256 fromCompany;
        uint256 toCompany;
        OperationCode operationCode;
        OperationStatus status;
        uint256 subjectCode;  // code of nomen. resource || company's product(like TVs)
        uint256 subjectAmount;
        uint256 ttokensAmount;
        uint256 timestamp;
    }
    /* @note After mvp will be deprecated in favor of event listener
     * _operationsIn - top up only in ttoken
     * _operationsOut - withdrawal only in ttoken
     */
    mapping(address => Operation[]) private _operationsIn;
    mapping(address => Operation[]) private _operationsOut;
    
    struct Company {
       string name;
       address mainAddress;
    }
    // Company code => Company info
    mapping(uint256 => Company) private _company;
    uint256 private _totalCompanies;

    modifier onlyCompany(uint256 companyId) {
        require(_company[companyId].mainAddress == _msgSender());
        _;
    }

    constructor(
        string memory name, 
        string memory symbol,
        uint256 countryCode,
        address productOracle,
        address factory,
        uint256[] memory resourceIds,
        uint256[] memory balances
    ) ERC20(name, symbol) {
        require(countryCode != 0, "TToken: There is no country with zero code");
        require(productOracle != address(0), "TToken: Oracle address must be initialized");
        require(factory != address(0), "TToken: Factory address must be initialized");
        
        uint256 productsLen = balances.length;
        require(productsLen != 0, "TToken: zero length of price array for nomenclature of products");
        require(productsLen == resourceIds.length, "TToken: length of resourceIds and price arrays must be equal");

        _countryCode = countryCode;
        _productOracle = IOracle(productOracle);
        _factory = factory;
        uint256 i;
        for(i; i<productsLen; i++) {
            uint256 resourceId = resourceIds[i];
            require(
                balances[i] != 0, 
                "TToken: balance for product in nomenclature mustn'be zero"
            );
            _nomenclatureResources[resourceId] = balances[i];
        }
        _totalProductsInNomenclature = productsLen;
    }

    // No zero company, zero company for administrative use
    function addCompany(string calldata name) external {
        ++ _totalCompanies;
        _company[_totalCompanies] = Company(name, _msgSender());
    }

    // simulation 
    // due to the fact that, as for mvp, we can't work with real assets
    function topUpBalance(
        uint256 companyId, 
        uint256 nationalCurrency,  // to pay
        uint256 resourceId         // to find out rate for exchange
    ) 
        external 
        onlyCompany(companyId)
    {
        uint256 rate = getProductPrice(resourceId);
        uint256 toMint = (rate * nationalCurrency) / _productOracle.decimals();
        
        _mint(_msgSender(), toMint);
        _operationsIn[_msgSender()].push( 
            Operation(
                0, 
                companyId, 
                OperationCode.TopUp, 
                OperationStatus.Completed, 
                resourceId, 
                nationalCurrency, 
                toMint, 
                block.timestamp
            )
        );
    }

    // TToken sell
    function withdraw(
        uint256 companyId,
        uint256 ttokens, 
        uint256 resourceId
    )
        external
        onlyCompany(companyId)
    {
        uint256 rate = getProductPrice(resourceId);
        uint256 topUpInCurrency = (_productOracle.decimals() * ttokens) / rate;

        _burn(_msgSender(), ttokens);
        _operationsOut[_msgSender()].push( 
            Operation(
                companyId, 
                0, 
                OperationCode.Withdraw, 
                OperationStatus.Completed, 
                resourceId, 
                topUpInCurrency, 
                ttokens, 
                block.timestamp
            )
        );
    }

    function getProductPrice(uint256 productId) 
        public view 
        returns (uint256) 
    {
        return _productOracle.getProductPriceById(productId);
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