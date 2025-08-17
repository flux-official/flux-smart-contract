// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../core/Ownable.sol";
import "../library/Errors.sol";
import "../library/FeeLib.sol";
import "../interface/ISwap.sol";
import "../interface/IBridgeGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapStableCoin is Ownable, ISwap {
    // ============ Storage Slots ============
    bytes32 private constant OWNER_SLOT = keccak256("SwapStableCoin_owner_role");
    bytes32 private constant FEE_POLICY_SLOT = keccak256("SwapStableCoin_fee_policy");
    bytes32 private constant IN_TOKEN_FEE_SLOT = keccak256("SwapStableCoin_in_token_fee");
    bytes32 private constant OUT_TOKEN_FEE_SLOT = keccak256("SwapStableCoin_out_token_fee");
    bytes32 private constant BRIDGE_GATEWAY_SLOT = keccak256("SwapStableCoin_bridge_gateway");
    
    constructor() {
        // Store owner address in custom storage slot
        _setOwner(OWNER_SLOT, msg.sender);
    }
    
    /**
     * @dev Set fee information for a token pair
     * @param token0 token0 address
     * @param token1 token1 address
     * @param inTokenFee Fee for input token in basis points
     * @param outTokenFee Fee for output token in basis points
     */
    function setTokenPairFees(
        address token0,
        address token1,
        uint256 inTokenFee,
        uint256 outTokenFee
    ) external onlyOwner(OWNER_SLOT) {
        if (token0 == address(0) || token1 == address(0)) {
            revert Errors.InvalidTokenAddresses(token0, token1);
        }
        if (inTokenFee > 1e18 || outTokenFee > 1e18) {
            revert Errors.FeeExceedsLimit(inTokenFee > outTokenFee ? inTokenFee : outTokenFee, 1e18);
        }
        
        // Store fees for token0 -> token1 direction
        bytes32 slot01 = keccak256(abi.encodePacked(FEE_POLICY_SLOT, token0, token1));
        FeeLib.FeeInfo memory feeInfo01 = FeeLib.FeeInfo({
            inTokenFee: inTokenFee,
            outTokenFee: outTokenFee
        });
        
        // Store fees for token1 -> token0 direction (reversed)
        bytes32 slot10 = keccak256(abi.encodePacked(FEE_POLICY_SLOT, token1, token0));
        FeeLib.FeeInfo memory feeInfo10 = FeeLib.FeeInfo({
            inTokenFee: outTokenFee,
            outTokenFee: inTokenFee
        });
        
        assembly {
            sstore(slot01, feeInfo01)
            sstore(slot10, feeInfo10)
        }
        
        emit TokenPairFeesSet(token0, token1, inTokenFee, outTokenFee);
        emit TokenPairFeesSet(token1, token0, outTokenFee, inTokenFee);
    }
    
    /**
     * @dev Set bridge gateway address (only owner)
     * @param _bridgeGateway New bridge gateway address
     */
    function setBridgeGateway(address _bridgeGateway) external onlyOwner(OWNER_SLOT) {
        if (_bridgeGateway == address(0)) revert Errors.InvalidAddress(_bridgeGateway);
        
        assembly {
            sstore(BRIDGE_GATEWAY_SLOT, _bridgeGateway)
        }
        
        emit BridgeGatewaySet(_bridgeGateway);
    }

    
    /**
     * @dev Get total accumulated fees for a token pair
     * @param token0 First token address
     * @param token1 Second token address
     * @return inTokenFee0to1 Total accumulated in-token fees for token0 -> token1 direction
     * @return outTokenFee0to1 Total accumulated out-token fees for token0 -> token1 direction
     * @return inTokenFee1to0 Total accumulated in-token fees for token1 -> token0 direction
     * @return outTokenFee1to0 Total accumulated out-token fees for token1 -> token0 direction
     */
    function getTotalFees(address token0, address token1) external view override returns (
        uint256 inTokenFee0to1, 
        uint256 outTokenFee0to1, 
        uint256 inTokenFee1to0, 
        uint256 outTokenFee1to0
    ) {
        // Get in-token fees for token0 -> token1 direction
        bytes32 inSlot0to1 = keccak256(abi.encodePacked(IN_TOKEN_FEE_SLOT, token0, token1));
        inTokenFee0to1 = FeeLib.getTotalFee(inSlot0to1);
        
        // Get out-token fees for token0 -> token1 direction
        bytes32 outSlot0to1 = keccak256(abi.encodePacked(OUT_TOKEN_FEE_SLOT, token0, token1));
        outTokenFee0to1 = FeeLib.getTotalFee(outSlot0to1);
        
        // Get in-token fees for token1 -> token0 direction
        bytes32 inSlot1to0 = keccak256(abi.encodePacked(IN_TOKEN_FEE_SLOT, token1, token0));
        inTokenFee1to0 = FeeLib.getTotalFee(inSlot1to0);
        
        // Get out-token fees for token1 -> token0 direction
        bytes32 outSlot1to0 = keccak256(abi.encodePacked(OUT_TOKEN_FEE_SLOT, token1, token0));
        outTokenFee1to0 = FeeLib.getTotalFee(outSlot1to0);
        
        return (inTokenFee0to1, outTokenFee0to1, inTokenFee1to0, outTokenFee1to0);
    }
    
    /**
     * @dev Swap tokens with 1:1 ratio and accumulate fees
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Amount of input tokens to swap
     * @param to Address to receive the output tokens
     * @return amountOut Output amount after fees
     * @return inTokenFee Fee amount for input token
     * @return outTokenFee Fee amount for output token
     */
    function swap(address tokenIn, address tokenOut, uint256 amountIn, address to) external override returns (uint256 amountOut, uint256 inTokenFee, uint256 outTokenFee) {
        if (tokenIn == address(0) || tokenOut == address(0)) {
            revert Errors.InvalidTokenAddresses(tokenIn, tokenOut);
        }
        if (amountIn == 0) {
            revert Errors.InvalidAmount(amountIn);
        }
        if (tokenIn == tokenOut) {
            revert Errors.SameTokenSwap(tokenIn);
        }
        
        // Get fee information for this token pair
        bytes32 feeSlot = keccak256(abi.encodePacked(FEE_POLICY_SLOT, tokenIn, tokenOut));
        FeeLib.FeeInfo memory feeInfo;
        
        assembly {
            feeInfo := sload(feeSlot)
        }
        
        // Calculate fees
        inTokenFee = (amountIn * feeInfo.inTokenFee) / 1e18;
        outTokenFee = (amountIn * feeInfo.outTokenFee) / 1e18;
        
        // Calculate output amount (1:1 ratio minus fees)
        amountOut = amountIn - outTokenFee;
        
        // Accumulate in-token fees for this direction
        bytes32 inTokenFeeSlot = keccak256(abi.encodePacked(IN_TOKEN_FEE_SLOT, tokenIn, tokenOut));
        FeeLib.addToTotalFee(inTokenFeeSlot, inTokenFee);
        
        // Accumulate out-token fees for this direction
        bytes32 outTokenFeeSlot = keccak256(abi.encodePacked(OUT_TOKEN_FEE_SLOT, tokenIn, tokenOut));
        FeeLib.addToTotalFee(outTokenFeeSlot, outTokenFee);
        
        // Transfer input tokens from user to contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        
        // Transfer output tokens from contract to specified address
        IERC20(tokenOut).transfer(to, amountOut);
        
        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut, inTokenFee + outTokenFee);
    }
    
    /**
     * @dev Swap tokens to other chain through bridge gateway
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param to Destination address
     * @param sourceChainId Source chain ID
     * @param destChainId Destination chain ID
     * @param amount Amount of tokens to bridge
     */
    function swapToOtherChain(
        address tokenIn,
        address tokenOut,
        address to,
        uint256 sourceChainId,
        uint256 destChainId,
        uint256 amount
    ) external {
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
        
        // Get bridge gateway address
        address bridgeGateway;
        assembly {
            bridgeGateway := sload(BRIDGE_GATEWAY_SLOT)
        }
        
        if (bridgeGateway == address(0)) {
            revert Errors.BridgeGatewayNotSet();
        }
        
        // Calculate and collect in-token fee
        bytes32 feeSlot = keccak256(abi.encodePacked(FEE_POLICY_SLOT, tokenIn, tokenOut));
        FeeLib.FeeInfo memory feeInfo;
        
        assembly {
            feeInfo := sload(feeSlot)
        }
        
        uint256 inTokenFee = (amount * feeInfo.inTokenFee) / 1e18;
        
        // Transfer tokens from user to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        
        // Transfer fee amount to fee collection
        if (inTokenFee > 0) {
            // Accumulate in-token fees
            bytes32 inTokenFeeSlot = keccak256(abi.encodePacked(IN_TOKEN_FEE_SLOT, tokenIn, tokenOut));
            FeeLib.addToTotalFee(inTokenFeeSlot, inTokenFee);
        }
        
        // Approve bridge gateway to spend the full amount
        IERC20(tokenIn).approve(bridgeGateway, amount);
        
        // Call bridge gateway exit function
        IBridgeGateway(bridgeGateway).exit(
            tokenIn,
            tokenOut,
            msg.sender,
            to,
            sourceChainId,
            destChainId,
            amount
        );
        
        emit SwapToOtherChain(tokenIn, tokenOut, msg.sender, to, sourceChainId, destChainId, amount, inTokenFee);
    }
    
    event TokenPairFeesSet(address indexed tokenIn, address indexed tokenOut, uint256 inTokenFee, uint256 outTokenFee);
    event SwapExecuted(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, uint256 totalFees);
    event BridgeGatewaySet(address indexed bridgeGateway);
    event SwapToOtherChain(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed from,
        address to,
        uint256 sourceChainId,
        uint256 destChainId,
        uint256 amount,
        uint256 inTokenFee
    );
}
