// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

library StakeLib {
    bytes32 private constant TOTAL_STAKED_AMOUNT_SLOT = keccak256("Stake_total_staked_amount");
    bytes32 private constant USER_STAKED_AMOUNT_SLOT = keccak256("Stake_user_staked_amount");
    
    /**
     * @dev Get total staked amount for a token
     * @param token Token address
     * @return Total staked amount
     */
    function getTotalStakedAmount(address token) internal view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(TOTAL_STAKED_AMOUNT_SLOT, token));
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }
    
    /**
     * @dev Set total staked amount for a token
     * @param token Token address
     * @param amount Amount to set
     */
    function setTotalStakedAmount(address token, uint256 amount) internal {
        bytes32 slot = keccak256(abi.encodePacked(TOTAL_STAKED_AMOUNT_SLOT, token));
        assembly {
            sstore(slot, amount)
        }
    }
    
    /**
     * @dev Get user's staked amount for a specific token
     * @param user User address
     * @param token Token address
     * @return User's staked amount
     */
    function getUserStakedAmount(address user, address token) internal view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(USER_STAKED_AMOUNT_SLOT, user, token));
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }
    
    /**
     * @dev Set user's staked amount for a specific token
     * @param user User address
     * @param token Token address
     * @param amount Amount to set
     */
    function setUserStakedAmount(address user, address token, uint256 amount) internal {
        bytes32 slot = keccak256(abi.encodePacked(USER_STAKED_AMOUNT_SLOT, user, token));
        assembly {
            sstore(slot, amount)
        }
    }
    
    /**
     * @dev Add amount to total staked amount
     * @param token Token address
     * @param amount Amount to add
     */
    function addToTotalStakedAmount(address token, uint256 amount) internal {
        uint256 currentTotal = getTotalStakedAmount(token);
        setTotalStakedAmount(token, currentTotal + amount);
    }
    
    /**
     * @dev Subtract amount from total staked amount
     * @param token Token address
     * @param amount Amount to subtract
     */
    function subtractFromTotalStakedAmount(address token, uint256 amount) internal {
        uint256 currentTotal = getTotalStakedAmount(token);
        setTotalStakedAmount(token, currentTotal - amount);
    }
    
    /**
     * @dev Add amount to user's staked amount
     * @param user User address
     * @param token Token address
     * @param amount Amount to add
     */
    function addToUserStakedAmount(address user, address token, uint256 amount) internal {
        uint256 currentUserAmount = getUserStakedAmount(user, token);
        setUserStakedAmount(user, token, currentUserAmount + amount);
    }
    
    /**
     * @dev Subtract amount from user's staked amount
     * @param user User address
     * @param token Token address
     * @param amount Amount to subtract
     */
    function subtractFromUserStakedAmount(address user, address token, uint256 amount) internal {
        uint256 currentUserAmount = getUserStakedAmount(user, token);
        setUserStakedAmount(user, token, currentUserAmount - amount);
    }
}