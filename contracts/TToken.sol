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
        address from;
        address to;
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

    // Company address => Company code (in THIS smart contract)
    mapping(address => uint256) private _company;
    address[] private _companyAddressById;
    // mapping(uint256 => address) private _company;
    uint256 private _totalCompanies;

    modifier onlyExistingCompany() {
        require(_company[_msgSender()] != 0);
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
        _companyAddressById.push(address(this));
    }

    // No zero company, zero company for administrative use
    function addCompany() external {
        ++_totalCompanies;
        _company[_msgSender()] = _totalCompanies;
        _companyAddressById.push(_msgSender()); 
    }

    // simulation
    // due to the fact that, as for mvp, we can't work with real assets
    function topUpBalance(
        uint256 nationalCurrency, // to pay
        uint256 resourceId // to find out rate for exchange
    ) external onlyExistingCompany() {
        uint256 rate = getProductPrice(resourceId);
        uint256 toMint = (rate * nationalCurrency) / _ioracle.decimals();

        _mint(_msgSender(), toMint);
        _operationsIn[_msgSender()].push(
            Operation(
                address(this),
                _msgSender(),
                OperationCode.TopUp,
                OperationStatus.Completed,
                resourceId,
                nationalCurrency,
                toMint,
                block.timestamp
            )
        );
        emit TopUpBalance(_msgSender(), nationalCurrency, toMint);
    }

    function topUpBalanceWithAnotherToken(
        address anotherToken,
        uint256 nationalCurrency, // to pay
        uint256 resourceId // to find out rate for exchange
    ) external onlyExistingCompany() {
        uint256 rate = getProductPrice(resourceId);
        uint256 toMint = (rate * nationalCurrency) / _ioracle.decimals();

        ITToken otherTToken = ITToken(anotherToken);
        uint256 thisContractBalanceInOtherToken = 
            otherTToken.balanceOf(address(this));
        if(thisContractBalanceInOtherToken < toMint) {
            toMint = thisContractBalanceInOtherToken;
            nationalCurrency = (toMint * _ioracle.decimals()) / rate;
        }

        otherTToken.transferFrom(address(this), _msgSender(), toMint);
        _mint(_msgSender(), toMint);

        _operationsIn[_msgSender()].push(
            Operation(
                address(this),
                _msgSender(),
                OperationCode.TopUp,
                OperationStatus.Completed,
                resourceId,
                nationalCurrency,
                toMint,
                block.timestamp
            )
        );
        emit TopUpBalanceWithAnotherToken(
            _msgSender(), 
            anotherToken, 
            nationalCurrency, 
            toMint
        );
    }

    // This TToken sell
    function withdraw(
        uint256 ttokens,
        uint256 resourceId
    ) external onlyExistingCompany() {
        uint256 rate = getProductPrice(resourceId);
        uint256 topUpInCurrency = (_ioracle.decimals() * ttokens) / rate;

        // sell TTokens to Central Bank for real national currency
        _burn(address(this), ttokens);
        _operationsOut[_msgSender()].push(
            Operation(
                _msgSender(),
                address(this), // smart contract TToken (acts like Central Bank entity)
                OperationCode.Withdraw,
                OperationStatus.Completed,
                resourceId,
                topUpInCurrency,
                ttokens,
                block.timestamp
            )
        );
        emit Withdraw(_msgSender(), topUpInCurrency, ttokens);
    }

    /* Other TToken sell (of another country)
     * number of 'ttokens' must be approved for transferring to this contract.
     * So, before calling this function 'approve' on another TToken contract
     *   must be called first.
     * This TToken contract acts like Central Bank
     */
    function withdrawWithAnotherToken(
        address anotherToken,
        uint256 ttokens, 
        uint256 resourceId
    )
        external
        onlyExistingCompany()
    {
        uint256 rate = getProductPrice(resourceId);
        uint256 topUpInCurrency = (_ioracle.decimals() * ttokens) / rate;

        ITToken anotherTToken = ITToken(anotherToken);
        anotherTToken.transferFrom(_msgSender(), address(this), ttokens);

        _operationsOut[_msgSender()].push(
            Operation(
                _msgSender(),
                address(this), // smart contract TToken (acts like Central Bank entity)
                OperationCode.Withdraw,
                OperationStatus.Completed,
                resourceId,
                topUpInCurrency,
                ttokens,
                block.timestamp
            )
        );
        emit WithdrawWithAnotherToken(
            _msgSender(), 
            anotherToken,
            topUpInCurrency,
            ttokens
        );
    }

    // if msg.sender == company in THIS smart contract
    function transfer(address toCompanyAddress, uint256 ttokens) 
        external 
        returns (bool) 
    {
        require(
            toCompanyAddress != address(0),
            "TToken: Unappropriate company id for ttokens transfer"
        );

        /* как и в 'transferFrom', тут должна быть проверка того, 
         *   что 'toCompanyAddress' и вправду существует:
         *   проверка через обращение к factory, зная countryCode,
         *   если компания принадлежит не к данному ЦБ
         */

        _recordSimpleTransfer(
            _msgSender(),
            toCompanyAddress,
            ttokens
        );
        return super.transferERC20(toCompanyAddress, ttokens);
    }

    // For cases connected with approvals
    function transferFrom(
        address fromCompanyAddress,
        address toCompanyAddress,
        uint256 ttokens
    ) external returns (bool) {
        require(
            fromCompanyAddress != address(0),
            "TToken: fromCompanyAddress is zero"
        );
        require(
            toCompanyAddress != address(0),
            "TToken: toCompanyAddress is zero"
        );

        _recordSimpleTransfer(
            fromCompanyAddress,
            toCompanyAddress,
            ttokens
        );
        return super.transferFromERC20(fromCompanyAddress, toCompanyAddress, ttokens);
    }

    function _recordSimpleTransfer(
        address fromCompanyAddress,
        address toCompanyAddress,
        uint256 ttokens
    ) private {
        Operation memory operationToRecord = Operation(
            fromCompanyAddress,
            toCompanyAddress,
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

    function getCompanyAddressById(uint256 id) public view returns(address) {
        return _companyAddressById[id];
    }

    function getAllCompanies() external view returns(address[] memory) {
        return _companyAddressById;
    }

}