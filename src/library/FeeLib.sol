// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

library FeeLib {
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
}
