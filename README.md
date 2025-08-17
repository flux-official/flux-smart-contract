# Flux Smart Contract

Flux is a project that implements an upgradeable smart contract proxy pattern.

## Project Structure

```
src/
├── bridge/         # Bridge related contracts
│   ├── BridgeGateway.sol
│   └── Vault.sol
├── core/           # Core contracts
│   ├── FluxBase.sol
│   └── Ownable.sol
├── interface/      # Interface definitions
│   ├── IBridgeGateway.sol
│   ├── IStake.sol
│   └── ISwap.sol
├── library/        # Libraries and error definitions
│   ├── Errors.sol
│   └── FeeLib.sol
├── stake/          # Staking related contracts
│   └── Stake.sol
├── swap/           # Swap related contracts
│   └── SwapStableCoin.sol
└── Flux.sol        # Main proxy contract
```

## Key Features

- **FluxBase**: Basic implementation of proxy pattern
- **Errors**: Custom error definitions
- **Flux**: Main proxy contract
- **Bridge Gateway**: Cross-chain bridging functionality
- **Vault**: Secure token storage and management
- **Swap System**: Token swapping with fee management

## Interfaces

### ISwap
- **Purpose**: Defines the interface for token swapping functionality
- **Functions**:
  - `swap(address tokenIn, address tokenOut, uint256 amountIn, address to)`: Swaps tokens with 1:1 ratio
  - **Returns**: `(uint256 amountOut, uint256 inTokenFee, uint256 outTokenFee)`
  - `getTotalFees(address token0, address token1)`: Gets accumulated fees for both directions
  - **Returns**: `(uint256 inTokenFee0to1, uint256 outTokenFee0to1, uint256 inTokenFee1to0, uint256 outTokenFee1to0)`
  - `swapToOtherChain(address tokenIn, address tokenOut, address to, uint256 sourceChainId, uint256 destChainId, uint256 amount)`: Swaps tokens to other chain through bridge
  - **Returns**: `(uint256 amountOut, uint256 inTokenFee, uint256 outTokenFee)`

### IBridgeGateway
- **Purpose**: Defines the interface for cross-chain bridging functionality
- **Functions**:
  - `enter(address tokenIn, address tokenOut, address from, address to, uint256 sourceChainId, uint256 destChainId, uint256 amount)`: Initiates bridge entry
  - `exit(address tokenIn, address tokenOut, address from, address to, uint256 sourceChainId, uint256 destChainId, uint256 amount)`: Completes bridge exit

**Bridge Events:**
- `BridgeEnter`: Emitted when bridge entry is initiated
  - `tokenIn`: Input token address (indexed)
  - `tokenOut`: Output token address (indexed)
  - `from`: Source address (indexed)
  - `to`: Destination address
  - `sourceChainId`: Source chain ID
  - `destChainId`: Destination chain ID
  - `amount`: Amount of tokens to bridge
- `BridgeExit`: Emitted when bridge exit is completed
  - Same parameters as BridgeEnter

### IStake
- **Purpose**: Defines the interface for staking functionality
- **Functions**:
  - `stake(address token, uint256 amount)`: Stakes tokens
  - `unstake(address token, uint256 amount)`: Unstakes tokens
  - `claimRewards(address token)`: Claims staking rewards

## Tech Stack

- Solidity 0.8.30
- Foundry
- OpenZeppelin Contracts

## Installation and Usage

```bash
# Install dependencies
forge install

# Build
forge build

# Test
forge test
```

## License

MIT
