// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

library FeeLib {
    // Storage slot for token fees
    bytes32 private constant TOKEN_FEE_SLOT = keccak256("FeeLib_token_fee");
    uint256 private constant DEFAULT_FEE = 50000000000000000; // 5e16 (5%)
    
    // Struct for fee information (matching SwapStableCoin)
    struct FeeInfo {
        uint256 inTokenFee;    // Fee for input token (in basis points, e.g., 30 = 0.3%)
        uint256 outTokenFee;   // Fee for output token (in basis points, e.g., 30 = 0.3%)
    }
    
    /**
     * @dev Get total fee from storage slot
     * @param storageSlot Storage slot for total fee
     * @return Total accumulated fee amount
     */
    function getTotalFee(bytes32 storageSlot) internal view returns (uint256) {
        uint256 totalFee;
        assembly {
            totalFee := sload(storageSlot)
        }
        return totalFee;
    }
    
    /**
     * @dev Set total fee to storage slot
     * @param storageSlot Storage slot for total fee
     * @param amount Fee amount to set
     */
    function setTotalFee(bytes32 storageSlot, uint256 amount) internal {
        assembly {
            sstore(storageSlot, amount)
        }
    }
    
    /**
     * @dev Add fee to total fee
     * @param storageSlot Storage slot for total fee
     * @param amount Fee amount to add
     */
    function addToTotalFee(bytes32 storageSlot, uint256 amount) internal {
        uint256 currentTotal = getTotalFee(storageSlot);
        setTotalFee(storageSlot, currentTotal + amount);
    }
    
    /**
     * @dev Subtract fee from total fee
     * @param storageSlot Storage slot for total fee
     * @param amount Fee amount to subtract
     */
    function subtractFromTotalFee(bytes32 storageSlot, uint256 amount) internal {
        uint256 currentTotal = getTotalFee(storageSlot);
        require(currentTotal >= amount, "Insufficient total fee");
        setTotalFee(storageSlot, currentTotal - amount);
    }
    
    /**
     * @dev Reset total fee to zero
     * @param storageSlot Storage slot for total fee
     */
    function resetTotalFee(bytes32 storageSlot) internal {
        setTotalFee(storageSlot, 0);
    }
    
    /**
     * @dev Get token fee slot for a specific token pair
     * @param token  token address
     * @return Storage slot for the token pair fees
     */
    function getTokenFeeSlot(address token) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(TOKEN_FEE_SLOT, token));
    }

    /**
     * @dev Read FeeInfo from an arbitrary storage slot (no defaults applied).
     * @param storageSlot The base storage slot where FeeInfo is stored
     * @return feeInfo The FeeInfo exactly as stored
     */
    function getFeeInfo(bytes32 storageSlot) internal view returns (FeeInfo memory feeInfo) {
        uint256 inFee;
        uint256 outFee;
        assembly {
            inFee := sload(storageSlot)
            outFee := sload(add(storageSlot, 1))
        }
        feeInfo = FeeInfo({ inTokenFee: inFee, outTokenFee: outFee });
    }

    /**
     * @dev Write FeeInfo into an arbitrary storage slot, normalizing zeros to DEFAULT_FEE.
     * @param storageSlot The base storage slot where FeeInfo will be stored
     * @param feeInfo The FeeInfo to store; zero fields will be set to DEFAULT_FEE
     */
    function setFeeInfo(bytes32 storageSlot, FeeInfo memory feeInfo) internal {
        uint256 inFee = feeInfo.inTokenFee == 0 ? DEFAULT_FEE : feeInfo.inTokenFee;
        uint256 outFee = feeInfo.outTokenFee == 0 ? DEFAULT_FEE : feeInfo.outTokenFee;
        assembly {
            sstore(storageSlot, inFee)
            sstore(add(storageSlot, 1), outFee)
        }
    }
}
