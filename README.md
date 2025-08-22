# Flux Smart Contract

Flux is a project that implements an upgradeable smart contract proxy pattern.

## Contract Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Request                            │
│                    (stake, swap, etc.)                        │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Flux.sol                                │
│                   (Proxy Contract)                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Function Selector Router                   │   │
│  │                                                         │   │
│  │  ┌─────────────────┐  ┌─────────────────────────────┐   │   │
│  │  │   IStake        │  │        ISwap                │   │   │
│  │  │   Functions     │  │      Functions              │   │   │
│  │  │                 │  │                             │   │   │
│  │  │ • stake()       │  │ • swap()                    │   │   │
│  │  │ • unstake()     │  │ • swapToOtherChain()        │   │   │
│  │  │ • claimRewards()│  │ • getTotalFees()            │   │   │
│  │  │ • getters...    │  │                             │   │   │
│  │  └─────────────────┘  └─────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │      Implementation         │
        │        Contracts            │
        │                             │
        │  ┌─────────────┐ ┌─────────┴─────────┐
        │  │   Stake.sol │ │   SwapStableCoin  │
        │  │             │ │       .sol        │
        │  │ • Staking   │ │ • Token Swapping  │
        │  │ • Rewards   │ │ • Fee Management  │
        │  │ • K-Factor  │ │ • Cross-chain     │
        │  │   Logic     │ │   Bridging        │
        │  └─────────────┘ └───────────────────┘
        └─────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Vault.sol                                   │
│              (Token Storage & Security)                        │
│                                                                 │
│  • Secure token storage and management                         │
│  • Access control and security measures                        │
│  • Deposit and withdrawal operations                           │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                BridgeGateway.sol                               │
│              (Cross-chain Bridge Logic)                        │
│                                                                 │
│  • Cross-chain token bridging                                  │
│  • Chain ID validation                                         │
│  • Bridge entry and exit operations                            │
│  • Integration with external bridge protocols                  │
└─────────────────────────────────────────────────────────────────┘
```

### How It Works

1. **User Request**: Users call functions like `stake()`, `swap()`, etc.
2. **Flux Proxy**: All requests go through `Flux.sol` (the proxy contract)
3. **Function Routing**: `Flux.sol` examines the function selector (first 4 bytes of calldata)
4. **Implementation Selection**: Based on the selector, requests are routed to:
   - **Stake.sol**: For staking-related functions (`stake`, `unstake`, `claimRewards`, etc.)
   - **SwapStableCoin.sol**: For swapping-related functions (`swap`, `swapToOtherChain`, etc.)
5. **Execution**: The selected implementation contract executes the requested function
6. **Response**: Results are returned through the proxy back to the user

### Key Benefits

- **Upgradeability**: Implementation contracts can be upgraded without changing the proxy
- **Single Entry Point**: Users only need to know one contract address (`Flux.sol`)
- **Gas Efficiency**: Direct delegation to implementation contracts
- **Consistent Interface**: All functions are accessible through a unified interface

## Kaia Testnet Contracts

| Contract | Address |
|----------|---------|
| MockToken1 | `0xadb14d6652d41064def81e671e37418c7949c18e` |
| MockToken2 | `0x3e4389a3b9c64d9e4402ed50db8a950134ac32af` |
| MockToken3 | `0xccb1454d890f8a377b31139d6eea53d3b630be36` |
| SwapStableCoin | `0x1ab301D7671F19215C904beEFF3Cc77C1937A8e9` |
| Stake | `0x6F7dC982af0cb0EA666F612a4F576DaB83d4b4d9` |
| Flux | `0xc60a367A18A1C72d33BB9370B39ef4A58BE344AD` |
| Vault | `0xe7261b77b2095e3fb78970bc8b1f4d6ab6b3ede6` |
| BridgeGateway | `0x0b6dadd958a84cb6c96e6306f38d2224c3ecbf7d` |

## Sepolia Testnet Contracts

| Contract | Address |
|----------|---------|
| MockToken1 | `0xadb14d6652d41064def81e671e37418c7949c18e` |
| MockToken2 | `0x3e4389a3b9c64d9e4402ed50db8a950134ac32af` |
| MockToken3 | `0xccb1454d890f8a377b31139d6eea53d3b630be36` |
| SwapStableCoin | `0x55C4Fd87BA46658D7e47FAAF66a2a2189f4e5B46` |
| Stake | `0x685c90Da0f28fb4D3d99bDbae01cf8d6ED82F4E3` |
| Flux | `0xf00c51CF495BFFf9D761f4aEAFad850e82771883` |
| Vault | `0x0b6dadd958a84cb6c96e6306f38d2224c3ecbf7d` |
| BridgeGateway | `0x78ffd77f5447cc972ba727546c1723db504a8681` |

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
├── mock/           # Mock contracts for testing
│   ├── MockToken1.sol
│   ├── MockToken2.sol
│   └── MockToken3.sol
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

## Mock Contracts

### Mock ERC20 Tokens
The project includes three mock ERC20 tokens for testing purposes:

- **MockToken1**: Mock token 1 with 18 decimals
- **MockToken2**: Mock token 2 with 18 decimals  
- **MockToken3**: Mock token 3 with 18 decimals

Each mock token includes:
- `mint(address to, uint256 amount)`: Mint new tokens (owner only)
- `burn(address from, uint256 amount)`: Burn tokens from specific address (owner only)
- `burn(uint256 amount)`: Burn tokens from caller's address
- Standard ERC20 functionality
- All tokens use 18 decimals for consistency

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

## Stake Contract Functions

The `Stake` contract implements a comprehensive staking system with the following functions:

### State Changing Functions (External)
- **`stake(address token, uint256 amount)`**: 
  - Stakes the specified amount of tokens from the caller
  - Automatically claims any pending rewards before adding new stake
  - Updates total and user staked amounts for the token

- **`unstake(address token, uint256 amount)`**: 
  - Unstakes the specified amount of tokens back to the caller
  - Automatically claims any pending rewards before reducing stake
  - Requires sufficient staked amount, updates total and user staked amounts

- **`claimRewards(address token)`**: 
  - Manually claims pending rewards for the caller
  - Calculates rewards based on current stake and accumulated K rewards
  - Transfers reward tokens to the caller and updates claimed amounts

### View Functions for Stake Information (Public)
- **`getTotalStakedAmount(address token)`**: 
  - Returns the total amount of tokens staked for a specific token
  - Used for calculating overall staking pool size

- **`getUserStakedAmount(address user, address token)`**: 
  - Returns the amount of tokens staked by a specific user for a specific token
  - Used for calculating individual user's stake

### View Functions for Mining and Rewards (Public)
- **`getLastMineAmount(address token)`**: 
  - Returns the last recorded mining amount for a specific token
  - Used for tracking mining progress and calculating new rewards

- **`getTotalKRewards(address token)`**: 
  - Returns the total accumulated K rewards for a specific token
  - Represents the overall reward rate for the staking pool

- **`getUserKRewards(address user, address token)`**: 
  - Returns the user's accumulated K rewards for a specific token
  - Used for calculating individual user's reward rate

### View Functions for Claimed Amounts (Public)
- **`getTotalClaimedAmount(address token)`**: 
  - Returns the total amount of rewards claimed by all users for a specific token
  - Used for tracking overall reward distribution

- **`getUserClaimedAmount(address user, address token)`**: 
  - Returns the amount of rewards claimed by a specific user for a specific token
  - Used for tracking individual user's reward history

### View Functions for Share and Pending Rewards (Public)
- **`getUserSharePercentage(address user, address token)`**: 
  - Returns the user's current share percentage of the total staking pool
  - Returns value in basis points (1e18 = 100%)
  - Used for understanding user's stake proportion

- **`getPendingRewards(address user, address token)`**: 
  - Returns the amount of pending rewards for a specific user and token
  - Calculates rewards based on current K rewards and user's stake
  - Used for displaying unclaimed rewards to users

### Utility Functions (Public)
- **`verifyStakeConsistency(address token)`**: 
  - Verifies the consistency of stake data for a specific token
  - Returns true if the total staked amount is valid
  - Used for data integrity validation

## Staking Mechanism

The staking system uses a **K-factor based reward distribution** mechanism:

1. **K Calculation**: `K = (totalMined - lastMineAmount) * 1e18 / totalStakedAmount`
2. **User Rewards**: `userRewards = (currentK - userK) * userStakedAmount / 1e18`
3. **Automatic Claiming**: Rewards are automatically claimed during stake/unstake operations
4. **Proportional Distribution**: Rewards are distributed proportionally to each user's stake

## Key Features

- **Automatic Reward Claiming**: Rewards are automatically processed during stake/unstake
- **Proportional Reward Distribution**: Users receive rewards proportional to their stake
- **Comprehensive Tracking**: All stake amounts, rewards, and claims are tracked per token and user
- **Gas Efficient**: Uses assembly for storage operations and optimized calculations
- **Security**: Input validation and proper access control for all operations

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