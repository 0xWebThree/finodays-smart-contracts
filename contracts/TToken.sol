// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TERC.sol";
import "./../interfaces/ITToken.sol";
import "./../interfaces/IOracle.sol";

/*
Смарт-контракт торгового токена, создается фабрикой
*/

// Товарный токен
contract TToken is TERC, ITToken {
    // ISO code: http://www.davros.org/misc/iso3166.html
    uint256 private immutable _countryCode;

    // код биржевого товара => balance
    mapping(uint256 => uint256) private _nomenclatureResources;
    uint256 private _totalProductsInNomenclature;

    ITToken internal ittoken;
    IOracle internal immutable _ioracle;
    address internal immutable _factory;

    // Redemption - 'умное' погашение перевода товаром, частичное(если не хватает товара)
    enum OperationCode {
        TopUp,
        Transfer,
        Redemption,
        Withdraw
    }
    /*
     * all operation statuses will be 'Completed' in MVP
     * as if the verification oracle has worked
     */
    enum OperationStatus {
        Created,
        InProgress,
        Completed
    }
    struct Operation {
        uint256 fromCompany;
        uint256 toCompany;
        OperationCode operationCode;
        OperationStatus status;
        uint256 subjectCode; // if TTokens = 0 || code of nomen. resource || company's product(like TVs)
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
    ) TERC(name, symbol) {
        require(countryCode != 0, "TToken: There is no country with zero code");
        require(
            productOracle != address(0),
            "TToken: Oracle address must be initialized"
        );
        require(
            factory != address(0),
            "TToken: Factory address must be initialized"
        );

        uint256 productsLen = balances.length;
        require(
            productsLen != 0,
            "TToken: zero length of price array for nomenclature of products"
        );
        require(
            productsLen == resourceIds.length,
            "TToken: length of resourceIds and price arrays must be equal"
        );

        _countryCode = countryCode;
        _ioracle = IOracle(productOracle);
        _factory = factory;
        uint256 i;
        for (i; i < productsLen; i++) {
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
        ++_totalCompanies;
        _company[_totalCompanies] = Company(name, _msgSender());
    }

    // simulation
    // due to the fact that, as for mvp, we can't work with real assets
    function topUpBalance(
        uint256 companyId,
        uint256 nationalCurrency, // to pay
        uint256 resourceId // to find out rate for exchange
    ) external onlyCompany(companyId) {
        uint256 rate = getProductPrice(resourceId);
        uint256 toMint = (rate * nationalCurrency) / _ioracle.decimals();

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

    // This TToken sell
    function selfWithdraw(
        uint256 companyId,
        uint256 ttokens,
        uint256 resourceId
    ) external onlyCompany(companyId) {
        uint256 rate = getProductPrice(resourceId);
        uint256 topUpInCurrency = (_ioracle.decimals() * ttokens) / rate;

        // sell TTokens to Central Bank for real national currency
        _burn(address(this), ttokens);
        _operationsOut[_msgSender()].push(
            Operation(
                companyId,
                0, // smart contract TToken (acts like Central Bank entity)
                OperationCode.Withdraw,
                OperationStatus.Completed,
                resourceId,
                topUpInCurrency,
                ttokens,
                block.timestamp
            )
        );
    }

    /* Other TToken sell (of another country)
     * number of 'ttokens' must be approved for transferring to this contract.
     * So, before calling this function 'approve' on another TToken contract
     *   must be called first.
     * This TToken contract acts like Central Bank
     */
    /*  function otherWithdraw(
        address otherToken,
        uint256 companyId,
        uint256 ttokens, 
        uint256 resourceId
    )
        external
        onlyCompany(companyId)
    {
        IERC20 otherTToken = IERC20(otherToken);
        otherTToken.transferFrom(_msgSender(), address(this), ttokens);

    }

    function _withdraw(
        uint256 companyId,
        uint256 ttokens, 
        uint256 resourceId
    )
        private
    {
        uint256 rate = getProductPrice(resourceId);
        uint256 topUpInCurrency = (_ioracle.decimals() * ttokens) / rate;
         
        _operationsOut[_msgSender()].push( 
            Operation(
                companyId, 
                0,         // smart contract TToken (acts like Central Bank entity)
                OperationCode.Withdraw, 
                OperationStatus.Completed, 
                resourceId, 
                topUpInCurrency, 
                ttokens, 
                block.timestamp
            )
        );
    }
*/
    function getProductPrice(uint256 productId) public view returns (uint256) {
        return _ioracle.getProductPriceById(productId);
    }

    function getCountryCode() public view returns (uint256) {
        return _countryCode;
    }

    function getFactoryAddress() public view returns (address) {
        return _factory;
    }

    function getOracleAddress() public view returns (address) {
        return address(_ioracle);
    }

    // if msg.sender == company main address
    function transfer(
        uint256 fromCompanyId,
        uint256 toCompanyId,
        uint256 ttokens
    ) 
        external 
        onlyCompany(fromCompanyId) 
        returns (bool) 
    {
        address toCompanyAddress = _company[toCompanyId].mainAddress;
        require(
            toCompanyAddress != address(0),
            "TToken: Unappropriate company id for ttokens transfer"
        );

        _recordSimpleTransfer(
            fromCompanyId,
            toCompanyId,
            _msgSender(),
            toCompanyAddress,
            ttokens
        );
        return super.transferERC20(toCompanyAddress, ttokens);
    }

    // for cases connected with approvals
    function transferFrom(
        uint256 fromCompanyId,
        uint256 toCompanyId,
        uint256 ttokens
    ) external returns (bool) {
        address fromCompanyAddress = _company[fromCompanyId].mainAddress;
        require(
            fromCompanyAddress != address(0),
            "TToken: Unappropriate from company id for ttokens transfer"
        );
        address toCompanyAddress = _company[toCompanyId].mainAddress;
        require(
            toCompanyAddress != address(0),
            "TToken: Unappropriate to company id for ttokens transfer"
        );

        _recordSimpleTransfer(
            fromCompanyId,
            toCompanyId,
            fromCompanyAddress,
            toCompanyAddress,
            ttokens
        );
        return super.transferFromERC20(fromCompanyAddress, toCompanyAddress, ttokens);
    }

    function _recordSimpleTransfer(
        uint256 fromCompanyId,
        uint256 toCompanyId,
        address fromCompanyAddress,
        address toCompanyAddress,
        uint256 ttokens
    ) private {
        Operation memory operationToRecord = Operation(
            fromCompanyId,
            toCompanyId,
            OperationCode.Transfer,
            OperationStatus.Completed,
            0,
            ttokens,
            ttokens,
            block.timestamp
        );
        _operationsIn[toCompanyAddress].push(operationToRecord);
        _operationsOut[fromCompanyAddress].push(operationToRecord);
    }

    function totalSupply()
        public
        view
        override(ITToken, TERC)
        returns (uint256) {}

    function balanceOf(
        address account
    ) public view override(ITToken, TERC) returns (uint256) {}

    function allowance(
        address owner,
        address spender
    ) public view override(ITToken, TERC) returns (uint256) {}

    function approve(
        address spender,
        uint256 amount
    ) public override(ITToken, TERC) returns (bool) {}
}