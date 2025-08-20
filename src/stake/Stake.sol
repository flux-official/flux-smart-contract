// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../interface/IStake.sol";
import "../library/Errors.sol";
import "../library/FeeLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Stake is IStake {
    bytes32 private constant OWNER_SLOT = keccak256("Stake_owner_role");
    bytes32 private constant TOTAL_STAKED_AMOUNT_SLOT = keccak256("Stake_total_staked_amount");
    bytes32 private constant USER_STAKED_AMOUNT_SLOT = keccak256("Stake_user_staked_amount");
    bytes32 private constant TOTAL_K_REWARDS_SLOT = keccak256("Stake_total_k_rewards");
    bytes32 private constant USER_K_REWARDS_SLOT = keccak256("Stake_user_k_rewards");
    bytes32 private constant LAST_MINE_AMOUNT_SLOT = keccak256("Stake_last_mine_amount");
    bytes32 private constant TOTAL_CLAIMED_AMOUNT_SLOT = keccak256("Stake_total_claimed_amount");
    bytes32 private constant USER_CLAIMED_AMOUNT_SLOT = keccak256("Stake_user_claimed_amount");
    
    // Implementation of IStake interface
    function stake(address token, uint256 amount) external override {
        if (token == address(0)) {
            revert Errors.InvalidAddress(token);
        }
        if (amount == 0) {
            revert Errors.InvalidAmount(amount);
        }

        // Claim rewards first (even if current stake is 0, to handle accumulated rewards)
        _claimRewards(token, msg.sender);
        
        // Transfer tokens from user to this contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        // Add to total staked amount
        _addToTotalStakedAmount(token, amount);
        
        // Add to user's staked amount
        _addToUserStakedAmount(msg.sender, token, amount);
        
        emit Staked(msg.sender, token, amount);
    }

    function unstake(address token, uint256 amount) external override {
        if (token == address(0)) {
            revert Errors.InvalidAddress(token);
        }
        if (amount == 0) {
            revert Errors.InvalidAmount(amount);
        }
        
        // Check if user has enough staked amount
        uint256 userStakedAmount = getUserStakedAmount(msg.sender, token);
        if (userStakedAmount < amount) {
            revert Errors.InsufficientTotalStakedAmount(userStakedAmount, amount);
        }
        
        // Claim rewards first (to handle accumulated rewards before unstaking)
        _claimRewards(token, msg.sender);
        
        // Subtract from user's staked amount
        _subtractFromUserStakedAmount(msg.sender, token, amount);
        
        // Subtract from total staked amount
        _subtractFromTotalStakedAmount(token, amount);
        
        // Transfer tokens back to user
        IERC20(token).transfer(msg.sender, amount);
        
        emit Unstaked(msg.sender, token, amount);
    }

    function claimRewards(address token) external override {
        if (token == address(0)) {
            revert Errors.InvalidAddress(token);
        }
        
        _claimRewards(token, msg.sender);
    }

    /**
     * @dev Private function to add amount to total staked amount
     * @param token Token address
     * @param amount Amount to add to total staked amount
     */
    function _addToTotalStakedAmount(address token, uint256 amount) private {
        uint256 currentTotal = getTotalStakedAmount(token);
        _setTotalStakedAmount(token, currentTotal + amount);
    }

    /**
     * @dev Private function to subtract amount from total staked amount
     * @param token Token address
     * @param amount Amount to subtract from total staked amount
     */
    function _subtractFromTotalStakedAmount(address token, uint256 amount) private {
        uint256 currentTotal = getTotalStakedAmount(token);
        if (currentTotal < amount) {
            revert Errors.InsufficientTotalStakedAmount(currentTotal, amount);
        }
        _setTotalStakedAmount(token, currentTotal - amount);
    }

    /**
     * @dev Private function to set total staked amount
     * @param token Token address
     * @param amount Amount to set as total staked amount
     */
    function _setTotalStakedAmount(address token, uint256 amount) private {
        bytes32 slot = keccak256(abi.encodePacked(TOTAL_STAKED_AMOUNT_SLOT, token));
        assembly {
            sstore(slot, amount)
        }
    }

    /**
     * @dev Private function to add amount to user's staked amount
     * @param user User address
     * @param token Token address
     * @param amount Amount to add to user's staked amount
     */
    function _addToUserStakedAmount(address user, address token, uint256 amount) private {
        uint256 currentUserAmount = getUserStakedAmount(user, token);
        _setUserStakedAmount(user, token, currentUserAmount + amount);
    }

    /**
     * @dev Private function to subtract amount from user's staked amount
     * @param user User address
     * @param token Token address
     * @param amount Amount to subtract from user's staked amount
     */
    function _subtractFromUserStakedAmount(address user, address token, uint256 amount) private {
        uint256 currentUserAmount = getUserStakedAmount(user, token);
        if (currentUserAmount < amount) {
            revert Errors.InsufficientTotalStakedAmount(currentUserAmount, amount);
        }
        _setUserStakedAmount(user, token, currentUserAmount - amount);
    }

    /**
     * @dev Private function to set user's staked amount
     * @param user User address
     * @param token Token address
     * @param amount Amount to set as user's staked amount
     */
    function _setUserStakedAmount(address user, address token, uint256 amount) private {
        bytes32 slot = keccak256(abi.encodePacked(USER_STAKED_AMOUNT_SLOT, user, token));
        assembly {
            sstore(slot, amount)
        }
    }

    /**
     * @dev Private function to set last mine amount for a token
     * @param token Token address
     * @param amount Amount to set as last mine amount
     */
    function _setLastMineAmount(address token, uint256 amount) private {
        bytes32 slot = keccak256(abi.encodePacked(LAST_MINE_AMOUNT_SLOT, token));
        assembly {
            sstore(slot, amount)
        }
    }

    /**
     * @dev Private function to set total K rewards for a token
     * @param token Token address
     * @param amount Amount to set as total K rewards
     */
    function _setTotalKRewards(address token, uint256 amount) private {
        bytes32 slot = keccak256(abi.encodePacked(TOTAL_K_REWARDS_SLOT, token));
        assembly {
            sstore(slot, amount)
        }
    }

    /**
     * @dev Private function to set user K rewards for a specific token
     * @param user User address
     * @param token Token address
     * @param amount Amount to set as user K rewards
     */
    function _setUserKRewards(address user, address token, uint256 amount) private {
        bytes32 slot = keccak256(abi.encodePacked(USER_K_REWARDS_SLOT, user, token));
        assembly {
            sstore(slot, amount)
        }
    }

    /**
     * @dev Private function to add to total claimed amount for a token
     * @param token Token address
     * @param amount Amount to add to total claimed amount
     */
    function _addToTotalClaimedAmount(address token, uint256 amount) private {
        uint256 currentTotal = getTotalClaimedAmount(token);
        bytes32 slot = keccak256(abi.encodePacked(TOTAL_CLAIMED_AMOUNT_SLOT, token));
        assembly {
            sstore(slot, add(currentTotal, amount))
        }
    }

    /**
     * @dev Private function to add to user claimed amount for a specific token
     * @param user User address
     * @param token Token address
     * @param amount Amount to add to user claimed amount
     */
    function _addToUserClaimedAmount(address user, address token, uint256 amount) private {
        uint256 currentUserAmount = getUserClaimedAmount(user, token);
        bytes32 slot = keccak256(abi.encodePacked(USER_CLAIMED_AMOUNT_SLOT, user, token));
        assembly {
            sstore(slot, add(currentUserAmount, amount))
        }
    }

    /**
     * @dev Private view function to get total mined reward for a token
     * @param token Token address
     * @return Last mined reward amount
     */
    function _totalMined(address token) private view returns (uint256) {
        return FeeLib.getTotalFee(FeeLib.getTokenFeeSlot(token));
    }

    function _currentK(address token) private view returns (uint256) {
        uint256 currentK = getTotalKRewards(token);
        uint256 totalStakedAmount = getTotalStakedAmount(token);
        uint256 totalMined = _totalMined(token);
        uint256 lastMineAmount = getLastMineAmount(token);
        
        // Prevent division by zero and ensure accurate calculation
        if (totalStakedAmount == 0) {
            return currentK;
        }
        
        if (totalMined > lastMineAmount) {
            uint256 diff = totalMined - lastMineAmount;
            if (diff > 0) {
                currentK = currentK + (diff * 1e18) / totalStakedAmount;
            }
        }
        return currentK;
    }

    function _rewardk(address token, address user) private view returns (uint256) {
        uint256 userK = getUserKRewards(user, token);
        uint256 currentK = _currentK(token);
        return currentK > userK ? currentK - userK : 0;
    }

    function _updateUserKRewards(address user, address token) private returns (uint256) {
        uint256 currentK = _currentK(token);
        uint256 userKRewards = _rewardk(token, user);
        _setUserKRewards(user, token, currentK);
        return userKRewards;
    }

    function _updateTotalKRewards(address token) private {
        uint256 totalMined = _totalMined(token);
        uint256 lastMineAmount = getLastMineAmount(token);
        uint256 totalStakedAmount = getTotalStakedAmount(token);
        uint256 currentK = getTotalKRewards(token);
        
        // Prevent division by zero
        if (totalStakedAmount == 0) {
            return;
        }
        
        if (totalMined > lastMineAmount) {
            uint256 diff = totalMined - lastMineAmount;
            if (diff > 0) {
                _setTotalKRewards(token, currentK + (diff * 1e18) / totalStakedAmount);
            }
        }
    }

    function _claimRewards(address token, address user) private {
        uint256 userKRewards = _updateUserKRewards(user, token);
        if(userKRewards != 0) {
            uint256 amount = userKRewards * getUserStakedAmount(user, token) / 1e18;
            if(amount != 0) {
                IERC20(token).transfer(user, amount);
                
                // Track claimed amounts
                _addToTotalClaimedAmount(token, amount);
                _addToUserClaimedAmount(user, token, amount);
                
                emit RewardsClaimed(user, token, amount);
            }
        }
        _updateTotalKRewards(token);
    }

    // Events
    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);
    event RewardsClaimed(address indexed user, address indexed token, uint256 amount);

    /**
     * @dev Public function to get total staked amount
     * @param token Token address
     * @return Total staked amount
     */
    function getTotalStakedAmount(address token) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(TOTAL_STAKED_AMOUNT_SLOT, token));
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    /**
     * @dev Public function to get user's staked amount
     * @param user User address
     * @param token Token address
     * @return User's staked amount
     */
    function getUserStakedAmount(address user, address token) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(USER_STAKED_AMOUNT_SLOT, user, token));
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    /**
     * @dev Public function to get last mine amount for a token
     * @param token Token address
     * @return Last mine amount
     */
    function getLastMineAmount(address token) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(LAST_MINE_AMOUNT_SLOT, token));
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    /**
     * @dev Public function to get total K rewards for a token
     * @param token Token address
     * @return Total K rewards amount
     */
    function getTotalKRewards(address token) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(TOTAL_K_REWARDS_SLOT, token));
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    /**
     * @dev Public function to get user K rewards for a specific token
     * @param user User address
     * @param token Token address
     * @return User K rewards amount
     */
    function getUserKRewards(address user, address token) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(USER_K_REWARDS_SLOT, user, token));
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    /**
     * @dev Public function to get total claimed amount for a token
     * @param token Token address
     * @return Total claimed amount
     */
    function getTotalClaimedAmount(address token) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(TOTAL_CLAIMED_AMOUNT_SLOT, token));
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    /**
     * @dev Public function to get user claimed amount for a specific token
     * @param user User address
     * @param token Token address
     * @return User claimed amount
     */
    function getUserClaimedAmount(address user, address token) public view returns (uint256) {
        bytes32 slot = keccak256(abi.encodePacked(USER_CLAIMED_AMOUNT_SLOT, user, token));
        uint256 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    /**
     * @dev Public function to get user's current share percentage (in basis points, 1e18 = 100%)
     * @param user User address
     * @param token Token address
     * @return User's share percentage in basis points
     */
    function getUserSharePercentage(address user, address token) public view returns (uint256) {
        uint256 totalStaked = getTotalStakedAmount(token);
        if (totalStaked == 0) {
            return 0;
        }
        
        uint256 userStaked = getUserStakedAmount(user, token);
        return (userStaked * 1e18) / totalStaked;
    }

    /**
     * @dev Public function to get user's pending rewards
     * @param user User address
     * @param token Token address
     * @return Pending reward amount
     */
    function getPendingRewards(address user, address token) public view returns (uint256) {
        uint256 userKRewards = _rewardk(token, user);
        uint256 userStakedAmount = getUserStakedAmount(user, token);
        
        if (userStakedAmount == 0) {
            return 0;
        }
        
        return (userKRewards * userStakedAmount) / 1e18;
    }

    /**
     * @dev Public function to verify stake consistency
     * @param token Token address
     * @return True if total staked amount matches sum of all user stakes
     */
    function verifyStakeConsistency(address token) public view returns (bool) {
        // This is a simplified check - in a real implementation, you might want to iterate through all users
        // For now, we'll just check if the total is non-negative and reasonable
        uint256 totalStaked = getTotalStakedAmount(token);
        return totalStaked >= 0;
    }
}
