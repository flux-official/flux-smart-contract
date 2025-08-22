// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../core/Ownable.sol";
import "../library/Errors.sol";
import "../library/FeeLib.sol";
import "../library/StakeLib.sol";
import "../interface/ISwap.sol";
import "../interface/IBridgeGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapStableCoin is Ownable, ISwap {
    // ============ Storage Slots ============
    bytes32 private constant OWNER_SLOT = keccak256("SwapStableCoin_owner_role");
    bytes32 private constant FEE_POLICY_SLOT = keccak256("SwapStableCoin_fee_policy");
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
        bytes32 bridgeGatewaySlot = BRIDGE_GATEWAY_SLOT;
        assembly {
            sstore(bridgeGatewaySlot, _bridgeGateway)
        }
        
        emit BridgeGatewaySet(_bridgeGateway);
    }

    
    /**
     * @dev Get total accumulated fees for a token pair
     * @param token0 First token address
     * @param token1 Second token address
     * @return token0Fee Total accumulated fees for token0
     * @return token1Fee Total accumulated fees for token1
     */
    function getTotalFees(address token0, address token1) external view override returns (
        uint256 token0Fee, 
        uint256 token1Fee
    ) { 
        return (FeeLib.getTotalFee(FeeLib.getTokenFeeSlot(token0)),FeeLib.getTotalFee(FeeLib.getTokenFeeSlot(token1)));
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
        
        // Accumulate fees for this 
        FeeLib.addToTotalFee(FeeLib.getTokenFeeSlot(tokenIn), inTokenFee);
        FeeLib.addToTotalFee(FeeLib.getTokenFeeSlot(tokenOut), outTokenFee);

        // Get current reserves using StakeLib getter functions
        uint256 inReserve = StakeLib.getTotalStakedAmount(tokenIn);
        uint256 outReserve = StakeLib.getTotalStakedAmount(tokenOut);
        
        // Update reserves using StakeLib setter functions
        StakeLib.setTotalStakedAmount(tokenIn, inReserve + amountIn);
        
        if (outReserve < amountOut) {
            revert Errors.InsufficientTotalStakedAmount(outReserve, amountOut);
        }
        StakeLib.setTotalStakedAmount(tokenOut, outReserve - amountOut);
        
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
    ) external returns (uint256 amountOut, uint256 inTokenFee, uint256 outTokenFee) {
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
        bytes32 bridgeGatewaySlot = BRIDGE_GATEWAY_SLOT;
        assembly {
            bridgeGateway := sload(bridgeGatewaySlot)
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
        
        inTokenFee = (amount * feeInfo.inTokenFee) / 1e18;
        
        // Transfer tokens from user to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        
        // Transfer fee amount to fee collection
        if (inTokenFee > 0) {
            // Accumulate in-token fees
            FeeLib.addToTotalFee(FeeLib.getTokenFeeSlot(tokenIn), inTokenFee);
        }

        // Update reserve using StakeLib setter function
        uint256 currentReserve = StakeLib.getTotalStakedAmount(tokenIn);
        StakeLib.setTotalStakedAmount(tokenIn, currentReserve + amount);
        
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
        
        // Calculate return values
        amountOut = amount - inTokenFee;
        outTokenFee = 0; // No out-token fee for cross-chain swaps
        
        emit SwapToOtherChain(tokenIn, tokenOut, msg.sender, to, sourceChainId, destChainId, amount, inTokenFee);
    }
    
    /**
     * @dev Get bridge gateway address from storage
     * @return Bridge gateway address
     */
    function _getBridgeGateway() private view returns (address) {
        bytes32 slot = BRIDGE_GATEWAY_SLOT;
        address bridgeGateway;
        assembly {
            bridgeGateway := sload(slot)
        }
        return bridgeGateway;
    }
    
    /**
     * @dev Calculate in-token fee for cross-chain swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amount Amount of tokens
     * @return In-token fee amount
     */
    function _calculateInTokenFee(address tokenIn, address tokenOut, uint256 amount) private view returns (uint256) {
        bytes32 feeSlot = keccak256(abi.encodePacked(FEE_POLICY_SLOT, tokenIn, tokenOut));
        FeeLib.FeeInfo memory feeInfo;
        
        assembly {
            feeInfo := sload(feeSlot)
        }
        
        return (amount * feeInfo.inTokenFee) / 1e18;
    }
    
    /**
     * @dev Update reserve for input token
     * @param tokenIn Input token address
     * @param amount Amount to add to reserve
     */
    function _updateReserve(address tokenIn, uint256 amount) private {
        uint256 currentReserve = StakeLib.getTotalStakedAmount(tokenIn);
        StakeLib.setTotalStakedAmount(tokenIn, currentReserve + amount);
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