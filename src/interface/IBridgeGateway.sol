// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IBridgeGateway {
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
    ) external;
    
    /**
     * @dev Exit bridge with specified parameters
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
    ) external;
}
