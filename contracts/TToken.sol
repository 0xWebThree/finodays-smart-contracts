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

    // код биржевого товара => balance/limit (в TToken)
    mapping(uint256 => uint256) private _nomenclatureResources;
    uint256[] private _nomenclatureResourceIds; // для фронта

    ITToken internal ittoken;
    IOracle internal immutable _ioracle;
    address internal immutable _factory;

    // Redemption - 'умное' погашение перевода товаром, частичное(если не хватает товара)
    enum OperationCode {
        TopUp,
        TopUpWithAnotherToken,
        Transfer,
        Redemption,
        Withdraw,
        WithdrawWithAnotherToken
    }
    /*
     * all operation statuses will be 'Completed' in MVP
     * as if the verification oracle has worked
     */
    enum OperationStatus {
        Created,
        InProgress,
        Completed // заглушка. автоматом ставится. а так предполагаются стейты для изменения состояния транзакции через оракул/доверенную сторону
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
    /* @note After mvp mappings will be deprecated in favor of event listener
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
        require(
            _company[_msgSender()] != 0,
            "TToken: only connected to this Central Bank companies can call function"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 countryCode,
        address productOracle,
        address factory,
        uint256[] memory resourceIds,
        uint256[] memory resourceBalances
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

        uint256 productsLen = resourceBalances.length;
        require(
            productsLen != 0,
            "TToken: zero length of balance array for nomenclature of products"
        );
        require(
            productsLen == resourceIds.length,
            "TToken: length of resourceIds and balance arrays must be equal"
        );

        _countryCode = countryCode;
        _ioracle = IOracle(productOracle);
        _factory = factory;
        uint256 i;
        for (i; i < productsLen; i++) {
            uint256 resourceId = resourceIds[i];
            require(
                resourceBalances[i] != 0,
                "TToken: balance for product in nomenclature mustn'be zero"
            );
            _nomenclatureResources[resourceId] = resourceBalances[i];
            _nomenclatureResourceIds.push(resourceId);
        }
        // zero company, этот смарт для служебных целей
        _companyAddressById.push(address(this));
    }

    // zero company - this smart contract
    function addCompany() external {
        require(_company[_msgSender()] == 0, "TToken: company already exists");
        
        ++_totalCompanies;
        _company[_msgSender()] = _totalCompanies;
        _companyAddressById.push(_msgSender()); 
    }

    // концепция, заглушка.
    // когда цб покупает на внутреннем рынке товар(биржевой) за рубли
    function extendLimitToProductByCompany(
        uint256 nomenclatureResource, 
        uint256 limitToAdd
    ) 
        external
        onlyExistingCompany() // тк на внутреннем рынке только
    {
        require(
            nomenclatureResource != 0, 
            "TToken: nomenclature resource doesn't exist"
        );
        require(
            limitToAdd != 0, 
            "TToken: limit to add is zero"
        );
       _nomenclatureResources[nomenclatureResource] += limitToAdd;
    }

    // simulation
    // due to the fact that, as for mvp, we can't work with real assets
    function topUpBalance(
        uint256 nationalCurrency, // to pay
        uint256 resourceId // to find out rate for exchange
    ) external onlyExistingCompany() {
        uint256 rate = getProductRate(resourceId);
        uint256 toMint = (rate * nationalCurrency) / _ioracle.decimals();
        require(
            toMint != 0, 
            "TToken(02): too low amount of nationalCurrency to top up balance"
        );

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

    // Оптимизация клиринга
    // Сложное пополнение
    function topUpBalanceWithAnotherToken(
        address anotherToken,
        uint256 nationalCurrency, // to pay
        uint256 resourceId // to find out rate for exchange
    ) external onlyExistingCompany() {
        uint256 rate = getProductRate(resourceId);
        uint256 toMint = (rate * nationalCurrency) / _ioracle.decimals();

        ITToken otherTToken = ITToken(anotherToken);
        uint256 thisContractBalanceInOtherToken = 
            otherTToken.balanceOf(address(this));
        require(
            thisContractBalanceInOtherToken != 0,
            "TToken(01): not enough funds of another token in Central Bank"
        );
        if(thisContractBalanceInOtherToken < toMint) {
            toMint = thisContractBalanceInOtherToken;
            // заплатить меньше должен в реал активах, тк нехватка токенов у цб
            nationalCurrency = (toMint * _ioracle.decimals()) / rate;
        }
        require(
            toMint != 0 && nationalCurrency != 0, 
            "TToken(02): too low amount of nationalCurrency to top up balance"
        );

        // в рамках смарта otherToken это просто перевод. 
        // поэтому id = 0, обозначение чисто перевода токенов
        otherTToken.transfer(_msgSender(), toMint, 0, toMint); 

        _operationsIn[_msgSender()].push(
            Operation(
                anotherToken,
                _msgSender(),
                OperationCode.TopUpWithAnotherToken,
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
    ) 
        external 
        onlyExistingCompany() 
    {
        uint256 rate = getProductRate(resourceId);
        uint256 topUpInCurrency = (_ioracle.decimals() * ttokens) / rate;
        require(
            topUpInCurrency != 0,
            "TToken(02): too low amount of ttokens to withdraw"
        );

        // sell TTokens to Central Bank for real national currency
        _transfer(_msgSender(), address(this), ttokens);
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
     */
    // Оптимизация клиринга
    // Сложный вывод
    function withdrawWithAnotherToken(
        address anotherToken,
        uint256 ttokens, 
        uint256 resourceId
    )
        external
        onlyExistingCompany()
    {
        uint256 rate = getProductRate(resourceId);
        uint256 topUpInCurrency = (_ioracle.decimals() * ttokens) / rate;
        require(
            topUpInCurrency != 0,
            "TToken: too low amount of ttokens to withdraw"
        );

        ITToken anotherTToken = ITToken(anotherToken);
        anotherTToken.transferFrom(_msgSender(), address(this), 0, ttokens, ttokens);

        _operationsOut[_msgSender()].push(
            Operation(
                _msgSender(),
                anotherToken, // smart contract TToken (acts like Central Bank entity)
                OperationCode.WithdrawWithAnotherToken,
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

    function transfer(
        address toCompanyAddress, 
        uint256 ttokens, 
        uint256 productId,
        uint256 productAmount
    ) 
        external 
        returns (bool) 
    {
        require(
            toCompanyAddress != address(0),
            "TToken: Unappropriate company id for ttokens transfer"
        );
        if(productId != 0) 
            require(
                productAmount != 0,
                "TToken: product amount must be pozitive"
            );

        _recordProductTransfer(
            _msgSender(),
            toCompanyAddress,
            productId,
            productAmount,
            ttokens
        );
        return super.transferERC20(toCompanyAddress, ttokens);
    }

    // For cases connected with approvals
    function transferFrom(
        address fromCompanyAddress,
        address toCompanyAddress,
        uint256 productId,
        uint256 productAmount,
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

        _recordProductTransfer(
            fromCompanyAddress,
            toCompanyAddress,
            productId,
            productAmount,
            ttokens
        );
        return super.transferFromERC20(fromCompanyAddress, toCompanyAddress, ttokens);
    }

    // Умное частичное(если не хватает токенов на балансе у цб) погашение товарами
    function redemption(
        address toCompanyAddress, 
        uint256 resourceId, 
        uint256 ttokens  
    ) 
        external 
        returns (bool) 
    {
        require(
            toCompanyAddress != address(0),
            "TToken: toCompanyAddress is zero"
        );
        uint256 nomenclatureResourceBalance = _nomenclatureResources[resourceId];
        require(nomenclatureResourceBalance != 0,
          "TToken: unappropriate resourceId"
        );
        require(ttokens != 0,
          "TToken: unappropriate ttokens amount equal to zero"
        );
        // если превышение лимита(баланса), гасится максимум средств
        if(ttokens > nomenclatureResourceBalance) {
            ttokens = nomenclatureResourceBalance;
        }
        _nomenclatureResources[resourceId] -= ttokens;
        // если такого resourceId нет => revert tx
        // productId равный нулю, не принимается. тк обозначает сам токен
        uint256 rate = getProductRate(resourceId);
        uint256 inCurrency = (_ioracle.decimals() * ttokens) / rate;
        // чтобы копейки токенов не переводились
        require(
            inCurrency != 0, 
            "TToken(02): too low amount of ttokens to redempt"
        );

        Operation memory operationToRecord = Operation(
            _msgSender(),
            toCompanyAddress,
            OperationCode.Redemption,
            OperationStatus.Completed, // заглушка, автоматом ставится. концептуально преподлагается изменение стейтов
            resourceId,
            inCurrency,
            ttokens,
            block.timestamp
        );
        _operationsIn[toCompanyAddress].push(operationToRecord);
        _operationsOut[_msgSender()].push(operationToRecord);

        return super.transferERC20(toCompanyAddress, ttokens);
    }


    function _recordProductTransfer(
        address fromCompanyAddress,
        address toCompanyAddress,
        uint256 productId,
        uint256 productAmount,
        uint256 ttokens
    ) private {
        if(productId == 0) 
            productAmount = ttokens; // 0 - обозначение просто перевода торгового токена
        Operation memory operationToRecord = Operation(
            fromCompanyAddress,
            toCompanyAddress,
            OperationCode.Transfer,
            OperationStatus.Completed,
            productId,
            productAmount,
            ttokens,
            block.timestamp
        );
        _operationsIn[toCompanyAddress].push(operationToRecord);
        _operationsOut[fromCompanyAddress].push(operationToRecord);
    }

    function balanceOf(address account)
        public
        view
        override(ITToken, TERC)
        returns (uint256) {
            return super.balanceOf(account);
    }


    function getProductRate(uint256 productId) public view returns (uint256) {
        return _ioracle.getProductRateById(productId);
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

    function getOperationsInArrayByAddress(
        address person
    ) 
        external view 
        returns(Operation[] memory) 
    {
        return _operationsIn[person];
    }

    function getOperationsOutArrayByAddress(
        address person
    ) 
        external view 
        returns(Operation[] memory) 
    {
        return _operationsOut[person];
    }

    function getNomenclatureResourceBalance(uint256 resourceId) external view returns(uint256) {
        return _nomenclatureResources[resourceId];
    }

    function getCompanyId(address account) external view returns(uint256) {
        return _company[account];
    }

    function getAllNomenclatureResourceIds() external view returns(uint256[] memory) {
        return _nomenclatureResourceIds;
    }
}