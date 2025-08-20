// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../library/Errors.sol";
import "../interface/IStake.sol";
import "../interface/ISwap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FluxBase is Ownable {
    // Base contract for Flux functionality
    
    // Contract addresses for implementations
    address public stakeImplementation;
    address public swapImplementation;
    
    constructor(address _stakeImplementation, address _swapImplementation) Ownable(msg.sender) {
        if (_stakeImplementation == address(0)) revert Errors.InvalidAddress(_stakeImplementation);
        if (_swapImplementation == address(0)) revert Errors.InvalidAddress(_swapImplementation);
        
        stakeImplementation = _stakeImplementation;
        swapImplementation = _swapImplementation;
        
        // Set implementations for IStake interface functions
        _setStakeImplementations();
        
        // Set implementations for ISwap interface functions
        _setSwapImplementations();
    }
    
    // Mapping from function selector to implementation address
    mapping(bytes4 => address) public selectorToImplementation;
    
    function _getImplementation(bytes4 selector) internal view returns (address) {
        address implementation = selectorToImplementation[selector];
        if (implementation == address(0)) revert Errors.ImplementationNotFound(selector);
        return implementation;
    }

    /**
     * @dev Set implementation address for a function selector
     * @param selector Function selector
     * @param implementation Implementation contract address
     */
    function setImplementation(bytes4 selector, address implementation) external onlyOwner {
        if (implementation == address(0)) revert Errors.InvalidAddress(implementation);
        selectorToImplementation[selector] = implementation;
        emit ImplementationSet(selector, implementation);
    }
    
    /**
     * @dev Set all IStake interface function implementations to stake contract
     */
    function _setStakeImplementations() private {
        // IStake interface functions
        selectorToImplementation[IStake.stake.selector] = stakeImplementation;
        selectorToImplementation[IStake.unstake.selector] = stakeImplementation;
        selectorToImplementation[IStake.claimRewards.selector] = stakeImplementation;
        
        // IStake view functions
        selectorToImplementation[IStake.getTotalStakedAmount.selector] = stakeImplementation;
        selectorToImplementation[IStake.getUserStakedAmount.selector] = stakeImplementation;
        selectorToImplementation[IStake.getLastMineAmount.selector] = stakeImplementation;
        selectorToImplementation[IStake.getTotalKRewards.selector] = stakeImplementation;
        selectorToImplementation[IStake.getUserKRewards.selector] = stakeImplementation;
        selectorToImplementation[IStake.getTotalClaimedAmount.selector] = stakeImplementation;
        selectorToImplementation[IStake.getUserClaimedAmount.selector] = stakeImplementation;
        selectorToImplementation[IStake.getUserSharePercentage.selector] = stakeImplementation;
        selectorToImplementation[IStake.getPendingRewards.selector] = stakeImplementation;
        selectorToImplementation[IStake.verifyStakeConsistency.selector] = stakeImplementation;
    }
    
    /**
     * @dev Set all ISwap interface function implementations to swap contract
     */
    function _setSwapImplementations() private {
        // ISwap interface functions
        selectorToImplementation[ISwap.swap.selector] = swapImplementation;
        selectorToImplementation[ISwap.getTotalFees.selector] = swapImplementation;
        selectorToImplementation[ISwap.swapToOtherChain.selector] = swapImplementation;
    }
    
    /**
     * @dev Update stake implementation address
     * @param _stakeImplementation New stake implementation address
     */
    function updateStakeImplementation(address _stakeImplementation) external onlyOwner {
        if (_stakeImplementation == address(0)) revert Errors.InvalidAddress(_stakeImplementation);
        stakeImplementation = _stakeImplementation;
        _setStakeImplementations();
        emit StakeImplementationUpdated(_stakeImplementation);
    }
    
    /**
     * @dev Update swap implementation address
     * @param _swapImplementation New swap implementation address
     */
    function updateSwapImplementation(address _swapImplementation) external onlyOwner {
        if (_swapImplementation == address(0)) revert Errors.InvalidAddress(_swapImplementation);
        swapImplementation = _swapImplementation;
        _setSwapImplementations();
        emit SwapImplementationUpdated(_swapImplementation);
    }

    event ImplementationSet(bytes4 indexed selector, address indexed implementation);
    event StakeImplementationUpdated(address indexed newImplementation);
    event SwapImplementationUpdated(address indexed newImplementation);
}
