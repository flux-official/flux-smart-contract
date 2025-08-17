// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IStake {
    // State changing functions
    function stake(address token, uint256 amount) external;
    function unstake(address token, uint256 amount) external;
    function claimRewards(address token) external;
}
