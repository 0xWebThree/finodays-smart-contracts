// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Интерфейс для TToken.
 */
interface ITToken {
    event TopUpBalance(
        address indexed receiver, 
        uint256 inCurrency, 
        uint256 ttokens
    );
    event TopUpBalanceWithAnotherToken(
        address indexed receiver, 
        address indexed ttoken, 
        uint256 inCurrency, 
        uint256 ttokens
    );

    event Withdraw(
        address indexed sender, 
        uint256 inCurrency, 
        uint256 ttokens
    );
    event WithdrawWithAnotherToken(
        address indexed sender, 
        address indexed ttoken,
        uint256 inCurrency,  
        uint256 ttokens
    );

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address toCompanyAddress, 
        uint256 productId,
        uint256 productAmount,
        uint256 ttokens
    ) 
        external returns (bool);
    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address fromCompanyAddress,
        address toCompanyAddress,
        uint256 productId,
        uint256 productAmount,
        uint256 ttokens
    ) 
        external returns (bool);
}
