# IQ AI audit details
- Total Prize Pool: $35,000 in USDC
  - HM awards: $23,900 in USDC
  - QA awards: $1,000 in USDC
  - Judge awards: $2,800 in USDC
  - Validator awards: $1,800 in USDC 
  - Scout awards: $500 in USDC
  - Mitigation Review: $5,000 USDC
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts January 29, 2025 20:00 UTC
- Ends February 7, 2025 20:00 UTC

**Note re: risk level upgrades/downgrades**

Two important notes about judging phase risk adjustments: 
- High- or Medium-risk submissions downgraded to Low-risk (QA) will be ineligible for awards.
- Upgrading a Low-risk finding from a QA report to a Medium- or High-risk finding is not supported.

As such, wardens are encouraged to select the appropriate risk level carefully during the submission phase.

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2025-01-iq-ai/blob/main/4naly3er-report.md).

_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._

- The token will be IQ, so there is no need to review implementations with other tokens.
- Whitelisted proxies can be malicious - no need to raise this as an issue.
- The owner will be a multisig.
- Gas optimizations are not needed since this will be deployed on a cheap L2 chain.

# Overview

### [AIToken](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

- ERC20 Compliant Token which confers governeanve over `Agent` Contract.
- Contains ERC20Permit Functionality.
- Token contract is owned by the `Agent` Contract.
- Token Clock based on timestamp rather than blockNumber

### [Agent](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

- `Agent` Contract which allows for call forwarding to whitelisted implementaion contracts.
- Owner of the `Agent` is the `TokenGovernor` contract.
- Whitelists much be approved via the `AgentFactory` contract.
- Implementaions must adhere to the storage layout set forth in `Agent`
- Similar to EIP-897 upgradality pattern

### [AgentFactory](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

- Contract responsible for deploying the Agent Contract array
- On `createAgent()` call the factory will deploy several contracts:
  1. `Agent`
  2. `AIToken`
  3. `TokenGovernor`
  4. `LiquidityManager` --`initializeBootstrapPool()`--> 4.1 `BootstrapPool`
- AITokens in this step will be allocated between the `Agent`, `DAO` & `LiquidityManager` at this point.
- Users will have an option to perform an initial buy through the `BootstrapPool` contract on the initial call.

### [AgentRouter](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

- Contract used to route trades either buying or selling a given `AIToken`
- Will swap either through the `BootstrapPool` or a `Fraxswap` pair

### [BootstapPool](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

- Serves as an initial pool through with an `AIToken` can be traded.
- Owned by `LiquidityManager` contract.
- Very similar to X\*Y=K style AMM.

### [LiquidityManager](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

- Contract intended to move liquidity between the bootstrap pool and the fraxswap pair give certain conditions are met.

### [TokenGovernor](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)

- Governance contract based off of OZ `Governor.sol`
- Voting token is `AIToken` Governor address will have ownership rights over the `Agent` contract.


## Links

- **Previous audits:** N/A
- **Documentation:** N/A
- **Website:** https://iqai.com
- **X/Twitter:** https://x.com/IQAICOM

---

# Scope

*See [scope.txt](https://github.com/code-423n4/2025-01-iq-ai/blob/main/scope.txt)*

### Files in scope


| File   | Logic Contracts | Interfaces | nSLOC | Purpose | Libraries used |
| ------ | --------------- | ---------- | ----- | -----   | ------------ |
| /src/AIToken.sol | 1| **** | 38 | |@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol<br>@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol<br>@openzeppelin/contracts/utils/Nonces.sol<br>@openzeppelin/contracts/utils/types/Time.sol|
| /src/Agent.sol | 1| **** | 63 | |@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol<br>@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/proxy/Proxy.sol|
| /src/AgentFactory.sol | 1| **** | 217 | |@openzeppelin/contracts/interfaces/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/access/Ownable2Step.sol|
| /src/AgentRouter.sol | 1| **** | 100 | |@openzeppelin/contracts/interfaces/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol<br>dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol|
| /src/BootstrapPool.sol | 1| **** | 137 | |@openzeppelin/contracts/interfaces/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/utils/ReentrancyGuard.sol|
| /src/LiquidityManager.sol | 1| **** | 146 | |@openzeppelin/contracts/interfaces/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol<br>dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol<br>dev-fraxswap/src/contracts/core/libraries/Math.sol|
| /src/TokenGovernor.sol | 1| **** | 77 | |@openzeppelin/contracts/governance/Governor.sol<br>@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol<br>@openzeppelin/contracts/governance/extensions/GovernorVotes.sol<br>@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol<br>@openzeppelin/contracts/governance/utils/IVotes.sol<br>@openzeppelin/contracts/utils/types/Time.sol|
| **Totals** | **7** | **** | **778** | | |

### Files out of scope

*See [out_of_scope.txt](https://github.com/code-423n4/2025-01-iq-ai/blob/main/out_of_scope.txt)*

| File         |
| ------------ |
| ./script/Base.s.sol |
| ./script/Deploy.s.sol |
| ./src/interface/IBAMM.sol |
| ./src/interface/IBAMMFactory.sol |
| ./test/AITokenTest.sol |
| ./test/AgentFactoryTest.sol |
| ./test/AgentRouterTest.sol |
| ./test/AgentTest.sol |
| ./test/BootstrapPoolTest.sol |
| ./test/Helpers/SigUtils.sol |
| ./test/MoveLiquidityTest.sol |
| ./test/ProxyTest.sol |
| ./test/TokenGovernorTest.sol |
| Totals: 13 |

## Scoping Q &amp; A

| Question                                | Answer                       |
| --------------------------------------- | ---------------------------- |
| ERC20 used by the protocol              |       Any (all possible ERC20s)             |
| Test coverage                           |  93.09% |
| ERC721 used  by the protocol            |            any              |
| ERC777 used by the protocol             |           None                |
| ERC1155 used by the protocol            |              None            |
| Chains the protocol will be deployed on | Fraxtal  |

### ERC20 token behaviors in scope

| Question                                                                                                                                                   | Answer |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| [Missing return values](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#missing-return-values)                                                      |   Out of scope  |
| [Fee on transfer](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#fee-on-transfer)                                                                  |  Out of scope  |
| [Balance changes outside of transfers](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#balance-modifications-outside-of-transfers-rebasingairdrops) | Out of scope    |
| [Upgradeability](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#upgradable-tokens)                                                                 |   Out of scope  |
| [Flash minting](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#flash-mintable-tokens)                                                              | Out of scope    |
| [Pausability](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#pausable-tokens)                                                                      | Out of scope    |
| [Approval race protections](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#approval-race-protections)                                              | Out of scope    |
| [Revert on approval to zero address](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-approval-to-zero-address)                            | Out of scope    |
| [Revert on zero value approvals](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-zero-value-approvals)                                    | Out of scope    |
| [Revert on zero value transfers](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-zero-value-transfers)                                    | Out of scope    |
| [Revert on transfer to the zero address](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-transfer-to-the-zero-address)                    | Out of scope    |
| [Revert on large approvals and/or transfers](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-large-approvals--transfers)                  | Out of scope    |
| [Doesn't revert on failure](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#no-revert-on-failure)                                                   |  In scope   |
| [Multiple token addresses](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-zero-value-transfers)                                          | Out of scope    |
| [Low decimals ( < 6)](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#low-decimals)                                                                 |   Out of scope  |
| [High decimals ( > 18)](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#high-decimals)                                                              | Out of scope    |
| [Blocklists](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#tokens-with-blocklists)                                                                | Out of scope    |

### External integrations (e.g., Uniswap) behavior in scope:


| Question                                                  | Answer |
| --------------------------------------------------------- | ------ |
| Enabling/disabling fees (e.g. Blur disables/enables fees) | No   |
| Pausability (e.g. Uniswap pool gets paused)               |  No   |
| Upgradeability (e.g. Uniswap gets upgraded)               |   No  |


### EIP compliance checklist

N/A

# Additional context

## Main invariants

N/A

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


## Attack ideas (where to focus for bugs)

* Graduation of agents and transfer of LP to Fraxswap
* High severity risks around funds getting stuck or stolen from the protocol

## All trusted roles in the protocol

| Role                                | Description                       |
| --------------------------------------- | ---------------------------- |
| AgentFactory Owner                      | admin rights                |

## Describe any novel or unique curve logic or mathematical models implemented in the contracts:

N/A

## Running tests

```bash
git clone --recursive https://github.com/code-423n4/2025-01-iq-ai
cd 2025-01-iq-ai
pnpm i
forge test
```
To run code coverage
```bash
forge coverage
```
To run gas benchmarks
```bash
forge test --gas-report
```

![img](https://github.com/code-423n4/2025-01-iq-ai/blob/main/coverage.png?raw=true)

## Miscellaneous
Employees of IQ AI and employees' family members are ineligible to participate in this audit.

Code4rena's rules cannot be overridden by the contents of this README. In case of doubt, please check with C4 staff.

