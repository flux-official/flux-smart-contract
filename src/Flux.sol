// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./core/FluxBase.sol";

contract Flux is FluxBase {
    constructor(address _stakeImplementation, address _swapImplementation) FluxBase(_stakeImplementation, _swapImplementation) {}

    fallback() external {
        address implementation = _getImplementation(msg.sig);
        
        assembly("memory-safe") {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}