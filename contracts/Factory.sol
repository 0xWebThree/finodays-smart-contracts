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

    event tradePairCreated(address token, address oracle);

    function createTradePair(
        string memory name, 
        string memory symbol,
        uint256 countryCode,
        address system,
        uint256[] calldata prices,
        uint256[] calldata balances
    ) external {
        require(
            _tradePair[countryCode].token == address(0),
            "Factory: TToken contract is already created with specified country code"
        );

        address oracle = _createOracleContract(system);
        address token = _createTokenContract(
            name, 
            symbol, 
            countryCode, 
            oracle, 
            prices,
            balances
        );
        _tradePair[countryCode] = TradePair(token, oracle);

        emit tradePairCreated(token, oracle); 
    }

    function _createTokenContract(
        string memory name, 
        string memory symbol,
        uint256 countryCode,
        address oracle,
        uint256[] calldata prices,
        uint256[] calldata balances
    ) 
        internal returns(address) 
    {
        TToken newTTokenContract = new TToken(
            name,
            symbol,
            countryCode,
            oracle,
            address(this),
            prices,
            balances
        );
        return address(newTTokenContract);
    }

    function _createOracleContract(address system) 
       internal 
       returns(address) 
    {
        Oracle newOracleContract = new Oracle(
            system
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
