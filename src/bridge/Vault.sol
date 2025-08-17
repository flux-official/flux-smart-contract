// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../library/Errors.sol";

contract Vault is Ownable {
    // Events
    event TokensDeposited(address indexed token, address indexed from, uint256 amount);
    event TokensWithdrawn(address indexed token, address indexed to, uint256 amount);
    event EmergencyWithdraw(address indexed token, address indexed to, uint256 amount);
    event GatewaySet(address indexed previousGateway, address indexed newGateway);
    
    // State variables
    mapping(address => uint256) public tokenBalances;
    address public gateway;
    
    // Modifiers
    modifier onlyGateway() {
        if (msg.sender != gateway) revert Errors.NotAllowed(msg.sender);
        _;
    }
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Set gateway address (only owner)
     * @param _gateway New gateway address
     */
    function setGateway(address _gateway) external onlyOwner {
        if (_gateway == address(0)) revert Errors.InvalidAddress(_gateway);
        address previousGateway = gateway;
        gateway = _gateway;
        emit GatewaySet(previousGateway, _gateway);
    }
    
    /**
     * @dev Deposit tokens into vault (only gateway)
     * @param token Token address to deposit
     * @param amount Amount to deposit
     */
    function deposit(address token, uint256 amount) external onlyGateway {
        if (token == address(0)) revert Errors.InvalidAddress(token);
        if (amount == 0) revert Errors.InvalidAmount(amount);
        
        // Update balance
        tokenBalances[token] += amount;
        
        emit TokensDeposited(token, msg.sender, amount);
    }
    
    /**
     * @dev Withdraw tokens from vault (only gateway)
     * @param token Token address to withdraw
     * @param to Recipient address
     * @param amount Amount to withdraw
     */
    function withdraw(address token, address to, uint256 amount) external onlyGateway {
        if (token == address(0)) revert Errors.InvalidAddress(token);
        if (to == address(0)) revert Errors.InvalidAddress(to);
        if (amount == 0) revert Errors.InvalidAmount(amount);
        if (amount > tokenBalances[token]) revert Errors.InsufficientBalance(token, amount, tokenBalances[token]);
        
        // Update balance
        tokenBalances[token] -= amount;
        
        // Transfer tokens to recipient
        IERC20(token).transfer(to, amount);
        
        emit TokensWithdrawn(token, to, amount);
    }
    
    /**
     * @dev Emergency withdraw all tokens of a specific type (only owner)
     * @param token Token address to emergency withdraw
     * @param to Recipient address
     */
    function emergencyWithdraw(address token, address to) external onlyOwner {
        if (token == address(0)) revert Errors.InvalidAddress(token);
        if (to == address(0)) revert Errors.InvalidAddress(to);
        
        uint256 balance = tokenBalances[token];
        if (balance == 0) revert Errors.InsufficientBalance(token, 1, 0);
        
        // Reset balance
        tokenBalances[token] = 0;
        
        // Transfer all tokens to recipient
        IERC20(token).transfer(to, balance);
        
        emit EmergencyWithdraw(token, to, balance);
    }
    
    /**
     * @dev Get vault balance for a specific token
     * @param token Token address
     * @return Current balance of the token in vault
     */
    function getBalance(address token) external view returns (uint256) {
        return tokenBalances[token];
    }
}
