// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockToken1
 * @dev Mock token 1 for testing purposes
 * @dev Includes mint and burn functionality
 */
contract MockToken1 is ERC20, Ownable {
    uint8 private _decimals = 18; // 18 decimals

    constructor() ERC20("Mock Token 1", "MTK1") Ownable(msg.sender) {}

    /**
     * @dev Mint new tokens to the specified address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens from the specified address
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    /**
     * @dev Burn tokens from the caller's address
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
