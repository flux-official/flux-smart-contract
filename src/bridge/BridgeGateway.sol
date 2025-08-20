// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/ISwap.sol";
import "../interface/IBridgeGateway.sol";
import "./Vault.sol";

contract BridgeGateway is Ownable {
    // Immutable public variables
    address public immutable flux;
    address public immutable vault;
    
    // Mapping to store addresses that can request bridging
    mapping(address => bool) public bridgingAllowed;
    
        // Events
    event BridgingAllowed(address indexed addr, bool allowed);
    event BridgeEnter(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed from,
        address to,
        uint256 sourceChainId,
        uint256 destChainId,
        uint256 amount
    );
    event BridgeExit(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed from,
        address to,
        uint256 sourceChainId,
        uint256 destChainId,
        uint256 amount
    );
    
    // Modifiers
    modifier onlyAllowed(address addr) {
        if (!bridgingAllowed[addr]) revert Errors.NotAllowed(addr);
        _;
    }
    
    modifier onlyFlux() {
        if (msg.sender != flux) revert Errors.NotAllowed(msg.sender);
        _;
    }
    
    constructor(address _flux, address _vault) Ownable(msg.sender) {
        if (_flux == address(0)) revert Errors.InvalidAddress(_flux);
        if (_vault == address(0)) revert Errors.InvalidVaultAddress(_vault);
        
        flux = _flux;
        vault = _vault;
    }
    
    /**
     * @dev Enter bridge with specified parameters
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param from Source address
     * @param to Destination address
     * @param sourceChainId Source chain ID
     * @param destChainId Destination chain ID
     * @param amount Amount of tokens to bridge
     */
    function enter(
        address tokenIn,
        address tokenOut,
        address from,
        address to,
        uint256 sourceChainId,
        uint256 destChainId,
        uint256 amount
    ) external onlyAllowed(msg.sender) {
        // Validate parameters
        if (tokenIn == address(0) || tokenOut == address(0)) {
            revert Errors.InvalidTokenAddresses(tokenIn, tokenOut);
        }
        if (to == address(0)) {
            revert Errors.InvalidAddress(to);
        }
        if (amount == 0) {
            revert Errors.InvalidAmount(amount);
        }
        
        // Check if current chain is the destination chain
        uint256 currentChainId = block.chainid;
        if (currentChainId != destChainId) {
            revert Errors.InvalidChainId(currentChainId, destChainId);
        }
        
        // Withdraw tokenOut from vault
        Vault(vault).withdraw(tokenOut, address(this), amount);
        
        // Call swap function to exchange tokens and send to recipient
        // Note: We need to approve the swap contract to spend our tokens first
        IERC20(tokenOut).approve(address(flux), amount);
        
        // Call swap function through Flux proxy
        ISwap(flux).swap(
            tokenOut,  // tokenIn (we have tokenOut from vault)
            tokenOut,  // tokenOut (same token for direct transfer)
            amount,    // amountIn
            to         // recipient
        );
        
        emit BridgeEnter(tokenIn, tokenOut, from, to, sourceChainId, destChainId, amount);
    }
    
    /**
     * @dev Exit bridge with specified parameters (only Flux)
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param from Source address
     * @param to Destination address
     * @param sourceChainId Source chain ID
     * @param destChainId Destination chain ID
     * @param amount Amount of tokens to bridge
     */
    function exit(
        address tokenIn,
        address tokenOut,
        address from,
        address to,
        uint256 sourceChainId,
        uint256 destChainId,
        uint256 amount
    ) external onlyFlux {
        // Validate parameters
        if (tokenIn == address(0) || tokenOut == address(0)) {
            revert Errors.InvalidTokenAddresses(tokenIn, tokenOut);
        }
        if (from == address(0)) {
            revert Errors.InvalidAddress(from);
        }
        if (amount == 0) {
            revert Errors.InvalidAmount(amount);
        }
        
        // Check if current chain is the destination chain
        uint256 currentChainId = block.chainid;
        if (currentChainId != sourceChainId) {
            revert Errors.InvalidChainId(currentChainId, sourceChainId);
        }
        
        // Transfer tokenIn from Flux to this contract
        IERC20(tokenIn).transferFrom(flux, address(this), amount);
        
        // Deposit tokenIn to vault
        Vault(vault).deposit(tokenIn, amount);
        
        emit BridgeExit(tokenIn, tokenOut, from, to, sourceChainId, destChainId, amount);
    }
    
    /**
     * @dev Set whether an address can request bridging (only owner)
     * @param addr Address to set bridging permission
     * @param allowed Whether bridging is allowed for this address
     */
    function setBridgingAllowed(address addr, bool allowed) external onlyOwner {
        bridgingAllowed[addr] = allowed;
        emit BridgingAllowed(addr, allowed);
    }
}
