// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

library Errors {
    error ImplementationNotFound(bytes4 selector);
    error InvalidAddress(address addr);
    error InvalidTokenAddresses(address tokenIn, address tokenOut);
    error FeeExceedsLimit(uint256 fee, uint256 limit);
    error InvalidAmount(uint256 amount);
    error SameTokenSwap(address token);
    error InvalidChainId(uint256 currentChainId, uint256 expectedChainId);
    error InvalidVaultAddress(address vault);
    error BridgeGatewayNotSet();
}
