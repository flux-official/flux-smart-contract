// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IStake {
    // State changing functions
    function stake(address token, uint256 amount) external;
    function unstake(address token, uint256 amount) external;
    function claimRewards(address token) external;
    
    // View functions for stake information
    function getTotalStakedAmount(address token) external view returns (uint256);
    function getUserStakedAmount(address user, address token) external view returns (uint256);
    
    // View functions for mining and rewards
    function getLastMineAmount(address token) external view returns (uint256);
    function getTotalKRewards(address token) external view returns (uint256);
    function getUserKRewards(address user, address token) external view returns (uint256);
    
    // View functions for claimed amounts
    function getTotalClaimedAmount(address token) external view returns (uint256);
    function getUserClaimedAmount(address user, address token) external view returns (uint256);
    
    // View functions for share and pending rewards
    function getUserSharePercentage(address user, address token) external view returns (uint256);
    function getPendingRewards(address user, address token) external view returns (uint256);
    
    // Utility functions
    function verifyStakeConsistency(address token) external view returns (bool);
}
