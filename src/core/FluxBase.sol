// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "../library/Errors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FluxBase is Ownable {
    // Base contract for Flux functionality
    
    constructor() Ownable(msg.sender) {}
    
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

    event ImplementationSet(bytes4 indexed selector, address indexed implementation);
}
