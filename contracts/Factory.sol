// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TToken.sol";
import "./Oracle.sol";

contract Factory {
    struct TradePair {
        address token;
        address oracle;
    }
    // Country Code => address
    mapping(uint256 => TradePair) private _tradePair;

    event TradePairCreated(
        uint256 indexed countryCode, 
        address token, 
        address oracle
    );

    function createTradePair(
        string calldata name, 
        string calldata symbol,
        uint256 countryCode,
        address system,
        uint256[] calldata resourceIds,
        uint256[] calldata resourceRates,
        uint256[] calldata resourceBalances
    ) external {
        require(
            _tradePair[countryCode].token == address(0),
            "Factory: TToken contract is already created with specified country code"
        );

        address oracle = _createOracleContract(system, resourceIds, resourceRates);
        address token = _createTokenContract(
            name, 
            symbol, 
            countryCode, 
            oracle, 
            resourceIds,
            resourceBalances
        );
        _tradePair[countryCode] = TradePair(token, oracle);

        emit TradePairCreated(countryCode, token, oracle); 
    }

    function _createTokenContract(
        string calldata name, 
        string calldata symbol,
        uint256 countryCode,
        address oracle,
        uint256[] calldata resourceIds,
        uint256[] calldata resourceBalances
    ) 
        internal returns(address) 
    {
        TToken newTTokenContract = new TToken(
            name,
            symbol,
            countryCode,
            oracle,
            address(this),
            resourceIds,
            resourceBalances
        );
        return address(newTTokenContract);
    }

    function _createOracleContract(
        address system, 
        uint256[] calldata resourceIds, 
        uint256[] calldata resourceRates
    ) 
       internal 
       returns(address) 
    {
        Oracle newOracleContract = new Oracle(
            system, resourceIds, resourceRates
        );
        return address(newOracleContract);
    }

    function getTokenAddressByCountryCode(
        uint256 countryCode
    ) 
        external view 
        returns(address) 
    {
        return _tradePair[countryCode].token;
    }
    function getOracleAddressByCountryCode(
        uint256 countryCode
    ) 
        external view 
        returns(address) 
    {
        return _tradePair[countryCode].oracle;
    }
}
