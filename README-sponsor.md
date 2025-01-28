# IQ Agents Contracts

### [AIToken](src/AIToken.sol)

- ERC20 Compliant Token which confers governeanve over `Agent` Contract.
- Contains ERC20Permit Functionality.
- Token contract is owned by the `Agent` Contract.
- Token Clock based on timestamp rather than blockNumber

### [Agent](src/Agent.sol)

- `Agent` Contract which allows for call forwarding to whitelisted implementaion contracts.
- Owner of the `Agent` is the `TokenGovernor` contract.
- Whitelists much be approved via the `AgentFactory` contract.
- Implementaions must adhere to the storage layout set forth in `Agent`
- Similar to EIP-897 upgradality pattern

### [AgentFactory](src/AgentFactory.sol)

- Contract responsible for deploying the Agent Contract array
- On `createAgent()` call the factory will deploy several contracts:
  1. `Agent`
  2. `AIToken`
  3. `TokenGovernor`
  4. `LiquidityManager` --`initializeBootstrapPool()`--> 4.1 `BootstrapPool`
- AITokens in this step will be allocated between the `Agent`, `DAO` & `LiquidityManager` at this point.
- Users will have an option to perform an initial buy through the `BootstrapPool` contract on the initial call.

### [AgentRouter](src/AgentRouter.sol)

- Contract used to route trades either buying or selling a given `AIToken`
- Will swap either through the `BootstrapPool` or a `Fraxswap` pair

### [BootstapPool](src/BootstrapPool.sol)

- Serves as an initial pool through with an `AIToken` can be traded.
- Owned by `LiquidityManager` contract.
- Very similar to X\*Y=K style AMM.

### [LiquidityManager](src/LiquidityManager.sol)

- Contract intended to move liquidity between the bootstrap pool and the fraxswap pair give certain conditions are met.

### [TokenGovernor](src/TokenGovernor.sol)

- Governance contract based off of OZ `Governor.sol`
- Voting token is `AIToken` Governor address will have ownership rights over the `Agent` contract.

## Files In Scope

Date : 2025-01-23 16:08:58

Directory src/

Total : 9 files, 842 codes, 417 comments, 150 blanks, all 1409 lines

## Files

| filename                                                          | language | code | comment | blank | total |
| :---------------------------------------------------------------- | :------- | ---: | ------: | ----: | ----: |
| [src/AIToken.sol](/src/AIToken.sol)                               | Solidity |   43 |      15 |    10 |    68 |
| [src/Agent.sol](/src/Agent.sol)                                   | Solidity |   66 |      30 |    14 |   110 |
| [src/AgentFactory.sol](/src/AgentFactory.sol)                     | Solidity |  215 |     149 |    50 |   414 |
| [src/AgentRouter.sol](/src/AgentRouter.sol)                       | Solidity |  123 |      43 |    11 |   177 |
| [src/BootstrapPool.sol](/src/BootstrapPool.sol)                   | Solidity |  135 |      61 |    23 |   219 |
| [src/LiquidityManager.sol](/src/LiquidityManager.sol)             | Solidity |  161 |      61 |    17 |   239 |
| [src/TokenGovernor.sol](/src/TokenGovernor.sol)                   | Solidity |   90 |      48 |    21 |   159 |
| [src/interface/IBAMM.sol](/src/interface/IBAMM.sol)               | Solidity |    4 |       5 |     2 |    11 |
| [src/interface/IBAMMFactory.sol](/src/interface/IBAMMFactory.sol) | Solidity |    5 |       5 |     2 |    12 |

## Caveates

1. CurrencyToken is intended to be an IERC20 compatible token. This excludes tokens with `feeOnTransfer()`
   functionality, in addition to ERC777-like callback functionality.
2. Implementaion contracts for `Agent` are intended to inherit the storage layout of the base `Agent` contract. Using a
   pattern like so:

```
contract AdditionalFunctionalityForAgent is Agent {
    uint256 public someAdditionalState;

    constructor(
        string memory name,
        string memory symbol,
        string memory url,
        address _factory
    )
        Agent(name, symbol, url, _factory)
    { }

    function someAdditionalFunctionality() public { .... }
  }
```

3. Similarly it can also be assumed that the `AgentFactory` Owner will not whitelist and proxy Implementations which are
   malicious or interact with the base `Agent` state in a malicious manner.

# Local Setup

## Installation

`pnpm i`

## Compile

`forge build`

## Test

`forge test`

`forge test -w` watch for file changes

`forge test -vvv` show stack traces for failed tests

`forge coverage` outputs coverage summary to console

## Tooling

This repo uses the following tools:

- solhint & prettier for code formatting
- lint-staged & husky for pre-commit formatting checks
- solhint for code quality and style hints
- foundry for compiling, testing, and deploying

### Running Slither

- Install via python:

```
pip install slither-analyzer
```

- To run on repo (cwd should be root):

```
slither .
```
