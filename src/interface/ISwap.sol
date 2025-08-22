// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface ISwap {
    function swap(address tokenIn, address tokenOut, uint256 amountIn, address to) external returns (uint256 amountOut, uint256 inTokenFee, uint256 outTokenFee);
    
    function getTotalFees(address token0, address token1) external view returns (uint256 token0Fee, uint256 token1Fee);
    
    function swapToOtherChain(
        address tokenIn,
        address tokenOut,
        address to,
        uint256 sourceChainId,
        uint256 destChainId,
        uint256 amount
    ) external returns (uint256 amountOut, uint256 inTokenFee, uint256 outTokenFee);
    
    // Fee management functions
    function setTokenPairFees(
        address token0,
        address token1,
        uint256 inTokenFee,
        uint256 outTokenFee
    ) external;
    
    // Bridge gateway management functions
    function setBridgeGateway(address _bridgeGateway) external;
    
}
