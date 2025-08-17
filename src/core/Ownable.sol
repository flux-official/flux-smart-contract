// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

abstract contract Ownable {
    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Returns the address of the current owner.
     */
    function owner(bytes32 storageSlot) public view returns (address) {
        return _getOwner(storageSlot);
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(bytes32 storageSlot) {
        require(owner(storageSlot) == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(bytes32 storageSlot, address newOwner) public onlyOwner(storageSlot) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(storageSlot, newOwner);
        emit OwnershipTransferred(owner(storageSlot), newOwner);
    }
    
    /**
     * @dev Renounces ownership of the contract.
     * Can only be called by the current owner.
     */
    function renounceOwnership(bytes32 storageSlot) public onlyOwner(storageSlot) {
        _setOwner(storageSlot, address(0));
        emit OwnershipTransferred(owner(storageSlot), address(0));
    }
    
    /**
     * @dev Sets the owner address in custom storage slot
     */
    function _setOwner(bytes32 storageSlot, address newOwner) internal {
        assembly {
            sstore(storageSlot, newOwner)
        }
    }
    
    /**
     * @dev Gets the owner address from custom storage slot
     */
    function _getOwner(bytes32 storageSlot) internal view returns (address) {
        address ownerAddress;
        assembly {
            ownerAddress := sload(storageSlot)
        }
        return ownerAddress;
    }
}
