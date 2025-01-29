# Report


## Gas Optimizations


| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings) | 4 |
| [GAS-2](#GAS-2) | Using bools for storage incurs overhead | 3 |
| [GAS-3](#GAS-3) | For Operations that will not overflow, you could use unchecked | 97 |
| [GAS-4](#GAS-4) | Use Custom Errors instead of Revert Strings to save Gas | 3 |
| [GAS-5](#GAS-5) | Avoid contract existence checks by using low level calls | 11 |
| [GAS-6](#GAS-6) | Functions guaranteed to revert when called by normal users can be marked `payable` | 21 |
| [GAS-7](#GAS-7) | Using `private` rather than `public` for constants, saves gas | 3 |
| [GAS-8](#GAS-8) | Splitting require() statements that use && saves gas | 2 |
| [GAS-9](#GAS-9) | Increments/decrements can be unchecked in for-loops | 1 |
| [GAS-10](#GAS-10) | Use != 0 instead of > 0 for unsigned integer comparison | 18 |
### <a name="GAS-1"></a>[GAS-1] `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings)
This saves **16 gas per instance.**

*Instances (4)*:
```solidity
File: /src/BootstrapPool.sol

87:         currencyTokenFeeEarned += _amountIn - (_amountIn * fee) / 10_000;

107:         agentTokenFeeEarned += _amountIn - (_amountIn * fee) / 10_000;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

184:                             liquidityAmount += amountOut;

200:                             currencyAmount += amountOut;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="GAS-2"></a>[GAS-2] Using bools for storage incurs overhead
Use uint256(1) and uint256(2) for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

*Instances (3)*:
```solidity
File: /src/AgentFactory.sol

63:     mapping(address => bool) public allowedProxyImplementation;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/BootstrapPool.sol

42:     bool public killed;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

37:     bool public initialized = false;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="GAS-3"></a>[GAS-3] For Operations that will not overflow, you could use unchecked

*Instances (97)*:
```solidity
File: /src/AIToken.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

5: import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

6: import {ERC20Votes, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

7: import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

8: import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

21: uint256 constant INITAL_SUPPLY = 100_000_000 * 10 ** 18;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

4: import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

5: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

6: import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";

7: import {AIToken} from "./AIToken.sol";

8: import {AgentFactory} from "./AgentFactory.sol";

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

4: import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

5: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

6: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

7: import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

8: import {Agent} from "./Agent.sol";

9: import {AIToken} from "./AIToken.sol";

10: import {LiquidityManager} from "./LiquidityManager.sol";

37:     uint256 public tradingFee = 100; // 1%

104:         uint256 mintToDAOAmount = (token.totalSupply() * mintToDAO) / 10_000;

105:         uint256 mintToAgentAmount = (token.totalSupply() * mintToAgent) / 10_000;

106:         uint256 initialLiquidity = token.totalSupply() - mintToDAOAmount - mintToAgentAmount;

445:     error MintTODAOTooHigh(); // Revert w/n change dao fee

446:     error MintToAgentTooHigh(); // Revert w/n change agent fee

447:     error ShareToBammTooHigh(); // Revert w/n change bamm share

448:     error TradingFeeTooHigh(); // Revert w/n change trading fee

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/AgentRouter.sol

4: import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

5: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

6: import {AgentFactory} from "./AgentFactory.sol";

7: import {LiquidityManager} from "./LiquidityManager.sol";

8: import {BootstrapPool} from "./BootstrapPool.sol";

9: import {IFraxswapPair} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol";

10: import {IFraxswapFactory} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol";

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

```solidity
File: /src/BootstrapPool.sol

4: import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

5: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

6: import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

7: import {LiquidityManager} from "./LiquidityManager.sol";

68:         fee = 10_000 - _fee;

71:         phantomAmount = (_initialPrice * _bootstrapAmount) / 1e18;

87:         currencyTokenFeeEarned += _amountIn - (_amountIn * fee) / 10_000;

107:         agentTokenFeeEarned += _amountIn - (_amountIn * fee) / 10_000;

127:         _price = (_reserveCurrencyToken * 1e18) / _reserveAgentToken;

134:         _reserveCurrencyToken = phantomAmount + currencyToken.balanceOf(address(this)) - currencyTokenFeeEarned;

135:         _reserveAgentToken = agentToken.balanceOf(address(this)) - agentTokenFeeEarned;

150:         require(_amountIn > 0 && _reserveIn > 0 && _reserveOut > 0); // INSUFFICIENT_INPUT_AMOUNT/INSUFFICIENT_LIQUIDITY

151:         uint256 _amountInWithFee = _amountIn * fee;

152:         uint256 _numerator = _amountInWithFee * _reserveOut;

153:         uint256 _denominator = (_reserveIn * 10_000) + _amountInWithFee;

154:         _amountOut = _numerator / _denominator;

169:         require(_amountOut > 0 && _reserveIn > 0 && _reserveOut > 0); //INSUFFICIENT_INPUT_AMOUNT/INSUFFICIENT_LIQUIDITY

170:         uint256 _numerator = _amountOut * _reserveIn * 10_000;

171:         uint256 _denominator = (_reserveOut - _amountOut) * fee;

172:         _amountIn = _numerator / _denominator;

183:                 currencyToken.balanceOf(address(this)) - currencyTokenFeeEarned,

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

4: import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

5: import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

6: import {IFraxswapPair} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol";

7: import {IFraxswapFactory} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol";

8: import {Math} from "dev-fraxswap/src/contracts/core/libraries/Math.sol";

9: import {BootstrapPool} from "./BootstrapPool.sol";

10: import {AgentFactory} from "./AgentFactory.sol";

11: import {IBAMMFactory} from "./interface/IBAMMFactory.sol";

12: import {IBAMM} from "./interface/IBAMM.sol";

107:         _reserveCurrencyToken = _reserveCurrencyToken - bootstrapPool.phantomAmount();

111:             "Bootstrap end-criterion not reached"

117:         uint256 liquidityAmount = (currencyAmount * 1e18) / price;

148:             agentToken.safeTransfer(address(fraxswapPair), liquidityAmount / 1_000_000);

149:             currencyToken.safeTransfer(address(fraxswapPair), currencyAmount / 1_000_000);

151:             liquidityAmount = liquidityAmount - liquidityAmount / 1_000_000;

152:             currencyAmount = currencyAmount - currencyAmount / 1_000_000;

158:             for (uint256 i = 0; i < 3; ++i) {

171:                 if ((currencyAmount * uint256(reserveAgentTokens)) / uint256(reserveCurrency) > liquidityAmount) {

183:                             currencyAmount -= amountIn;

184:                             liquidityAmount += amountOut;

199:                             liquidityAmount -= amountIn;

200:                             currencyAmount += amountOut;

211:         uint256 amountToBamm = (fraxswapPair.balanceOf(address(this)) * AgentFactory(owner).shareToBamm()) / 10_000;

238:         uint256 prod = Math.sqrt(reserveOut * reserveIn) * Math.sqrt((reserveOut + tokenOut) * (reserveIn + tokenIn));

239:         uint256 minus = reserveIn * tokenOut + reserveOut * reserveIn;

240:         if (prod > minus) maxSell = (prod - minus) / (reserveOut + tokenOut);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

```solidity
File: /src/TokenGovernor.sol

4: import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";

5: import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";

6: import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

7: import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

8: import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

9: import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

10: import {Agent} from "./Agent.sol";

38:     uint32 public votingDelayInSeconds = 2 minutes; // 2 minutes in seconds

39:     uint32 public votingPeriodInSeconds = 5 minutes; // 5 minutes in seconds

40:     uint32 public proposalThresholdPercentage = 1; // 0.01%

55:         GovernorVotesQuorumFraction(4) // quorum is 25% (1/4th) of supply

76:         else return (token().getPastTotalSupply(Time.timestamp() - 1) * proposalThresholdPercentage) / 10_000;

83:         if (proposalThresholdPercentage > 1000) revert InvalidThreshold(); // Max 10%

92:         if (_votingPeriodInSeconds > 30 days) revert InvalidPeriod(); // Max 30 days

93:         if (_votingPeriodInSeconds < 3 days) revert InvalidPeriod(); // Min 3 days

102:         if (_votingDelayInSeconds > 7 days) revert InvalidDelay(); // Max 7 days

103:         if (_votingDelayInSeconds < 12 hours) revert InvalidDelay(); // Min 12 hours

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)

### <a name="GAS-4"></a>[GAS-4] Use Custom Errors instead of Revert Strings to save Gas
Custom errors are available from solidity version 0.8.4. Custom errors save [**~50 gas**](https://gist.github.com/IllIllI000/ad1bd0d29a0101b25e57c293b4b0c746) each time they're hit by [avoiding having to allocate and store the revert string](https://blog.soliditylang.org/2021/04/21/custom-errors/#errors-in-depth). Not defining the strings also save deployment gas

Additionally, custom errors can be used inside and outside of contracts (including interfaces and libraries).

Source: <https://blog.soliditylang.org/2021/04/21/custom-errors/>:

> Starting from [Solidity v0.8.4](https://github.com/ethereum/solidity/releases/tag/v0.8.4), there is a convenient and gas-efficient way to explain to users why an operation failed through the use of custom errors. Until now, you could already use strings to give more information about failures (e.g., `revert("Insufficient funds.");`), but they are rather expensive, especially when it comes to deploy cost, and it is difficult to use dynamic information in them.

Consider replacing **all revert strings** with custom errors in the solution, and particularly those that have multiple occurrences:

*Instances (3)*:
```solidity
File: /src/BootstrapPool.sol

110:         require(currencyToken.balanceOf(address(this)) >= currencyTokenFeeEarned, "INSUFFICIENT_LIQUIDITY");

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

96:         require(!initialized, "BootstrapPool already initialized");

104:         require(!bootstrapPool.killed(), "BootstrapPool already killed");

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="GAS-5"></a>[GAS-5] Avoid contract existence checks by using low level calls
Prior to 0.8.10 the compiler inserted extra code, including `EXTCODESIZE` (**100 gas**), to check for contract existence for external function calls. In more recent solidity versions, the compiler will not insert these checks if the external call has a return value. Similar behavior can be achieved in earlier versions by using low-level calls, since low level calls never check for contract existence

*Instances (11)*:
```solidity
File: /src/BootstrapPool.sol

110:         require(currencyToken.balanceOf(address(this)) >= currencyTokenFeeEarned, "INSUFFICIENT_LIQUIDITY");

119:         agentToken.safeTransfer(owner, agentToken.balanceOf(address(this)));

120:         currencyToken.safeTransfer(owner, currencyToken.balanceOf(address(this)));

134:         _reserveCurrencyToken = phantomAmount + currencyToken.balanceOf(address(this)) - currencyTokenFeeEarned;

135:         _reserveAgentToken = agentToken.balanceOf(address(this)) - agentTokenFeeEarned;

183:                 currencyToken.balanceOf(address(this)) - currencyTokenFeeEarned,

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

116:         uint256 currencyAmount = currencyToken.balanceOf(address(this));

123:         agentToken.safeTransfer(address(agent), agentToken.balanceOf(address(this)));

124:         currencyToken.safeTransfer(address(agent), currencyToken.balanceOf(address(this)));

211:         uint256 amountToBamm = (fraxswapPair.balanceOf(address(this)) * AgentFactory(owner).shareToBamm()) / 10_000;

220:         fraxswapPair.transfer(agent, fraxswapPair.balanceOf(address(this)));

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="GAS-6"></a>[GAS-6] Functions guaranteed to revert when called by normal users can be marked `payable`
If a function modifier such as `onlyOwner` is used, the function will revert if a normal user tries to pay the function. Marking the function as `payable` will lower the gas cost for legitimate callers because the compiler will not include checks for whether a payment was provided.

*Instances (21)*:
```solidity
File: /src/AIToken.sol

56:     function mint(address to, uint256 amount) external onlyOwner {

64:     function burn(address from, uint256 amount) external onlyOwner {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

78:     function initializeToken(AIToken _token) public onlyOwner {

95:     function setProxyImplementation(address _proxyImplementation) public onlyOwner onlyWhenAlive {

105:     function setStage(uint256 _stage) public onlyFactory {

113:     function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner onlyWhenAlive {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

223:     function setGovenerBytecode(bytes memory _newBytecode) external onlyOwner {

231:     function setAgentBytecode(bytes memory _newBytecode) external onlyOwner {

239:     function setLiquidityManagerBytecode(bytes memory _newBytecode) external onlyOwner {

248:     function setCreationFee(uint256 _creationFee) external onlyOwner {

256:     function setCurrencyToken(IERC20 _currencyToken) external onlyOwner {

264:     function setTradingFee(uint256 _tradingFee) external onlyOwner {

275:     function setTargetCCYLiquidity(uint256 _targetCCYLiquidity) external onlyOwner {

283:     function setInitialPrice(uint256 _initialPrice) external onlyOwner {

292:     function setShareToBamm(uint256 _shareToBamm) external onlyOwner {

304:     function setMintToDAO(uint256 _mintToDAO) external onlyOwner {

316:     function setMintToAgent(uint256 _mintToAgent) external onlyOwner {

328:     function setDefaultProxyImplementation(address _defaultProxyImplementation) external onlyOwner {

337:     function setAllowedProxyImplementation(address _proxyImplementation, bool _allowed) external onlyOwner {

357:     function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/BootstrapPool.sol

116:     function kill() external nonReentrant onlyOwner {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

### <a name="GAS-7"></a>[GAS-7] Using `private` rather than `public` for constants, saves gas
If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

*Instances (3)*:
```solidity
File: /src/AgentRouter.sol

35:     IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

```solidity
File: /src/LiquidityManager.sol

54:     IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);

56:     IBAMMFactory public constant bammFactory = IBAMMFactory(0x19928170D739139bfbBb6614007F8EEeD17DB0Ba);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="GAS-8"></a>[GAS-8] Splitting require() statements that use && saves gas

*Instances (2)*:
```solidity
File: /src/BootstrapPool.sol

150:         require(_amountIn > 0 && _reserveIn > 0 && _reserveOut > 0); // INSUFFICIENT_INPUT_AMOUNT/INSUFFICIENT_LIQUIDITY

169:         require(_amountOut > 0 && _reserveIn > 0 && _reserveOut > 0); //INSUFFICIENT_INPUT_AMOUNT/INSUFFICIENT_LIQUIDITY

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

### <a name="GAS-9"></a>[GAS-9] Increments/decrements can be unchecked in for-loops
In Solidity 0.8+, there's a default overflow check on unsigned integers. It's possible to uncheck this in for-loops and save some gas at each iteration, but at the cost of some code readability, as this uncheck cannot be made inline.

[ethereum/solidity#10695](https://github.com/ethereum/solidity/issues/10695)

The change would be:

```diff
- for (uint256 i; i < numIterations; i++) {
+ for (uint256 i; i < numIterations;) {
 // ...  
+   unchecked { ++i; }
}  
```

These save around **25 gas saved** per instance.

The same can be applied with decrements (which should use `break` when `i == 0`).

The risk of overflow is non-existent for `uint256`.

*Instances (1)*:
```solidity
File: /src/LiquidityManager.sol

158:             for (uint256 i = 0; i < 3; ++i) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="GAS-10"></a>[GAS-10] Use != 0 instead of > 0 for unsigned integer comparison

*Instances (18)*:
```solidity
File: /src/AIToken.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

2: pragma solidity >=0.8.25;

88:         if (creationFee > 0) {

116:         if (mintToDAOAmount > 0) token.safeTransfer(address(this), mintToDAOAmount);

117:         if (mintToAgentAmount > 0) token.safeTransfer(address(agent), mintToAgentAmount);

121:         if (_amountToBuy > 0) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/AgentRouter.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

```solidity
File: /src/BootstrapPool.sol

2: pragma solidity >=0.8.25;

150:         require(_amountIn > 0 && _reserveIn > 0 && _reserveOut > 0); // INSUFFICIENT_INPUT_AMOUNT/INSUFFICIENT_LIQUIDITY

169:         require(_amountOut > 0 && _reserveIn > 0 && _reserveOut > 0); //INSUFFICIENT_INPUT_AMOUNT/INSUFFICIENT_LIQUIDITY

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

2: pragma solidity >=0.8.25;

174:                     if (amountIn > 0) {

176:                         if (amountOut > 0) {

190:                     if (amountIn > 0) {

192:                         if (amountOut > 0) {

212:         if (amountToBamm > 0) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

```solidity
File: /src/TokenGovernor.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)


## Non Critical Issues


| |Issue|Instances|
|-|:-|:-:|
| [NC-1](#NC-1) | Use `string.concat()` or `bytes.concat()` instead of `abi.encodePacked` | 3 |
| [NC-2](#NC-2) | Constants should be in CONSTANT_CASE | 3 |
| [NC-3](#NC-3) | `constant`s should be defined rather than using magic numbers | 22 |
| [NC-4](#NC-4) | Control structures do not follow the Solidity Style Guide | 38 |
| [NC-5](#NC-5) | Default Visibility for constants | 1 |
| [NC-6](#NC-6) | Consider disabling `renounceOwnership()` | 3 |
| [NC-7](#NC-7) | Functions should not be longer than 50 lines | 51 |
| [NC-8](#NC-8) | Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor | 6 |
| [NC-9](#NC-9) | Consider using named mappings | 3 |
| [NC-10](#NC-10) | `address`s shouldn't be hard-coded | 3 |
| [NC-11](#NC-11) | Take advantage of Custom Error's return value property | 25 |
| [NC-12](#NC-12) | Use scientific notation (e.g. `1e18`) rather than exponentiation (e.g. `10**18`) | 1 |
| [NC-13](#NC-13) | Use Underscores for Number Literals (add an underscore every 3 digits) | 2 |
| [NC-14](#NC-14) | Variables need not be initialized to zero | 2 |
### <a name="NC-1"></a>[NC-1] Use `string.concat()` or `bytes.concat()` instead of `abi.encodePacked`
Solidity version 0.8.4 introduces `bytes.concat()` (vs `abi.encodePacked(<bytes>,<bytes>)`)

Solidity version 0.8.12 introduces `string.concat()` (vs `abi.encodePacked(<str>,<str>), which catches concatenation errors (in the event of a `bytes` data mixed in the concatenation)`)

*Instances (3)*:
```solidity
File: /src/AgentFactory.sol

160:         bytes memory bytecodeWithArgs = abi.encodePacked(

189:         bytes memory bytecodeWithArgs = abi.encodePacked(governorBytecode, abi.encode(_name, _token, _agent));

209:         bytes memory bytecodeWithArgs = abi.encodePacked(agentBytecode, abi.encode(name, symbol, url, address(this)));

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

### <a name="NC-2"></a>[NC-2] Constants should be in CONSTANT_CASE
For `constant` variable names, each word should use all capital letters, with underscores separating each word (CONSTANT_CASE)

*Instances (3)*:
```solidity
File: /src/AgentRouter.sol

35:     IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

```solidity
File: /src/LiquidityManager.sol

54:     IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);

56:     IBAMMFactory public constant bammFactory = IBAMMFactory(0x19928170D739139bfbBb6614007F8EEeD17DB0Ba);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="NC-3"></a>[NC-3] `constant`s should be defined rather than using magic numbers
Even [assembly](https://github.com/code-423n4/2022-05-opensea-seaport/blob/9d7ce4d08bf3c3010304a0476a785c70c0e90ae7/contracts/lib/TokenTransferrer.sol#L35-L39) can benefit from using readable constants instead of hex/numeric literals

*Instances (22)*:
```solidity
File: /src/AgentFactory.sol

37:     uint256 public tradingFee = 100; // 1%

104:         uint256 mintToDAOAmount = (token.totalSupply() * mintToDAO) / 10_000;

105:         uint256 mintToAgentAmount = (token.totalSupply() * mintToAgent) / 10_000;

265:         if (_tradingFee > 100) {

293:         if (_shareToBamm > 10_000) {

305:         if (_mintToDAO > 100) {

317:         if (_mintToAgent > 2000) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/BootstrapPool.sol

68:         fee = 10_000 - _fee;

87:         currencyTokenFeeEarned += _amountIn - (_amountIn * fee) / 10_000;

107:         agentTokenFeeEarned += _amountIn - (_amountIn * fee) / 10_000;

153:         uint256 _denominator = (_reserveIn * 10_000) + _amountInWithFee;

170:         uint256 _numerator = _amountOut * _reserveIn * 10_000;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

158:             for (uint256 i = 0; i < 3; ++i) {

211:         uint256 amountToBamm = (fraxswapPair.balanceOf(address(this)) * AgentFactory(owner).shareToBamm()) / 10_000;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

```solidity
File: /src/TokenGovernor.sol

38:     uint32 public votingDelayInSeconds = 2 minutes; // 2 minutes in seconds

39:     uint32 public votingPeriodInSeconds = 5 minutes; // 5 minutes in seconds

76:         else return (token().getPastTotalSupply(Time.timestamp() - 1) * proposalThresholdPercentage) / 10_000;

83:         if (proposalThresholdPercentage > 1000) revert InvalidThreshold(); // Max 10%

92:         if (_votingPeriodInSeconds > 30 days) revert InvalidPeriod(); // Max 30 days

93:         if (_votingPeriodInSeconds < 3 days) revert InvalidPeriod(); // Min 3 days

102:         if (_votingDelayInSeconds > 7 days) revert InvalidDelay(); // Max 7 days

103:         if (_votingDelayInSeconds < 12 hours) revert InvalidDelay(); // Min 12 hours

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)

### <a name="NC-4"></a>[NC-4] Control structures do not follow the Solidity Style Guide
See the [control structures](https://docs.soliditylang.org/en/latest/style-guide.html#control-structures) section of the Solidity Style Guide

*Instances (38)*:
```solidity
File: /src/Agent.sol

37:         if (msg.sender != address(factory)) revert NotFactory();

42:         if (stage == 0) revert NotAlive();

79:         if (token == AIToken(address(0))) token = _token;

106:         if (_stage > stage) stage = _stage;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

116:         if (mintToDAOAmount > 0) token.safeTransfer(address(this), mintToDAOAmount);

117:         if (mintToAgentAmount > 0) token.safeTransfer(address(agent), mintToAgentAmount);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/AgentRouter.sol

9: import {IFraxswapPair} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol";

10: import {IFraxswapFactory} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol";

35:     IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);

68:         if (agent == address(0)) revert AgentNotFound();

78:             IFraxswapPair fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(address(currencyToken), _agentToken));

88:         if (_amountOut < _minAmountOut) revert InsufficientAmountOut();

109:         if (agent == address(0)) revert AgentNotFound();

119:             IFraxswapPair fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(address(currencyToken), _agentToken));

129:         if (_amountOut < _minAmountOut) revert InsufficientAmountOut();

142:             if (agent == address(0)) revert AgentNotFound();

150:                 IFraxswapPair fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(_tokenIn, _tokenOut));

158:             if (agent == address(0)) revert AgentNotFound();

166:                 IFraxswapPair fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(_tokenIn, _tokenOut));

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

```solidity
File: /src/BootstrapPool.sol

45:         if (killed) revert BootstrapPoolKilled();

50:         if (msg.sender != owner) revert NotOwner();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

6: import {IFraxswapPair} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol";

7: import {IFraxswapFactory} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol";

54:     IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);

120:         IFraxswapPair fraxswapPair = addLiquidityToFraxswap(liquidityAmount, currencyAmount);

137:         fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(address(currencyToken), address(agentToken)));

140:             fraxswapPair = IFraxswapPair(fraxswapFactory.createPair(address(currencyToken), address(agentToken), fee));

215:             if (bamm == IBAMM(address(0))) bamm = IBAMM(bammFactory.createBamm(address(fraxswapPair)));

240:         if (prod > minus) maxSell = (prod - minus) / (reserveOut + tokenOut);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

```solidity
File: /src/TokenGovernor.sol

75:         if (agent.stage() == 0) return type(uint256).max;

82:         if (msg.sender != address(this)) revert NotGovernor();

83:         if (proposalThresholdPercentage > 1000) revert InvalidThreshold(); // Max 10%

91:         if (msg.sender != address(this)) revert NotGovernor();

92:         if (_votingPeriodInSeconds > 30 days) revert InvalidPeriod(); // Max 30 days

93:         if (_votingPeriodInSeconds < 3 days) revert InvalidPeriod(); // Min 3 days

101:         if (msg.sender != address(this)) revert NotGovernor();

102:         if (_votingDelayInSeconds > 7 days) revert InvalidDelay(); // Max 7 days

103:         if (_votingDelayInSeconds < 12 hours) revert InvalidDelay(); // Min 12 hours

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)

### <a name="NC-5"></a>[NC-5] Default Visibility for constants
Some constants are using the default visibility. For readability, consider explicitly declaring them as `internal`.

*Instances (1)*:
```solidity
File: /src/AIToken.sol

21: uint256 constant INITAL_SUPPLY = 100_000_000 * 10 ** 18;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

### <a name="NC-6"></a>[NC-6] Consider disabling `renounceOwnership()`
If the plan for your project does not include eventually giving up all ownership control, consider overwriting OpenZeppelin's `Ownable`'s `renounceOwnership()` function in order to disable it.

*Instances (3)*:
```solidity
File: /src/AIToken.sol

27: contract AIToken is ERC20Votes, ERC20Permit, Ownable {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

25: contract Agent is ERC721URIStorage, Ownable, Proxy {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

27: contract AgentFactory is Ownable2Step {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

### <a name="NC-7"></a>[NC-7] Functions should not be longer than 50 lines
Overly complex code can make understanding functionality more difficult, try to further modularize your code to ensure readability 

*Instances (51)*:
```solidity
File: /src/AIToken.sol

43:     function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {

48:     function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {

56:     function mint(address to, uint256 amount) external onlyOwner {

64:     function burn(address from, uint256 amount) external onlyOwner {

73:     function clock() public view override returns (uint48) {

81:     function CLOCK_MODE() public view override returns (string memory) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

78:     function initializeToken(AIToken _token) public onlyOwner {

83:     function _implementation() internal view override returns (address) {

95:     function setProxyImplementation(address _proxyImplementation) public onlyOwner onlyWhenAlive {

105:     function setStage(uint256 _stage) public onlyFactory {

113:     function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner onlyWhenAlive {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

187:     function deployGovernor(string memory _name, address _token, address _agent) internal returns (address _governor) {

223:     function setGovenerBytecode(bytes memory _newBytecode) external onlyOwner {

231:     function setAgentBytecode(bytes memory _newBytecode) external onlyOwner {

239:     function setLiquidityManagerBytecode(bytes memory _newBytecode) external onlyOwner {

248:     function setCreationFee(uint256 _creationFee) external onlyOwner {

256:     function setCurrencyToken(IERC20 _currencyToken) external onlyOwner {

264:     function setTradingFee(uint256 _tradingFee) external onlyOwner {

275:     function setTargetCCYLiquidity(uint256 _targetCCYLiquidity) external onlyOwner {

283:     function setInitialPrice(uint256 _initialPrice) external onlyOwner {

292:     function setShareToBamm(uint256 _shareToBamm) external onlyOwner {

304:     function setMintToDAO(uint256 _mintToDAO) external onlyOwner {

316:     function setMintToAgent(uint256 _mintToAgent) external onlyOwner {

328:     function setDefaultProxyImplementation(address _defaultProxyImplementation) external onlyOwner {

337:     function setAllowedProxyImplementation(address _proxyImplementation, bool _allowed) external onlyOwner {

346:     function setAgentStage(address _agent, uint256 _stage) external {

357:     function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {

366:     function numberOfAgents() external view returns (uint256) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/AgentRouter.sol

52:     function buy(address _agentToken, uint256 _amountIn, uint256 _minAmountOut) external returns (uint256 _amountOut) {

94:     function sell(address _agentToken, uint256 _amountIn, uint256 _minAmountOut) external returns (uint256 _amountOut) {

137:     function getAmountOut(address _tokenIn, address _tokenOut, uint256 _amountIn) external returns (uint256) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

```solidity
File: /src/BootstrapPool.sol

77:     function buy(uint256 _amountIn) external returns (uint256) {

85:     function buy(uint256 _amountIn, address _recipient) public nonReentrant notKilled returns (uint256) {

97:     function sell(uint256 _amountIn) external returns (uint256) {

105:     function sell(uint256 _amountIn, address _recipient) public nonReentrant notKilled returns (uint256) {

125:     function getPrice() external view notKilled returns (uint256 _price) {

133:     function getReserves() public view returns (uint256 _reserveCurrencyToken, uint256 _reserveAgentToken) {

142:     function getAmountOut(uint256 _amountIn, address _tokenIn) public view notKilled returns (uint256 _amountOut) {

161:     function getAmountIn(uint256 _amountOut, address _tokenOut) public view notKilled returns (uint256 _amountIn) {

178:     function maxSwapAmount(address _tokenIn) public view returns (uint256 _amountIn) {

204:     function token0() external view returns (address) {

209:     function token1() external view returns (address) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/TokenGovernor.sol

62:     function votingDelay() public view override returns (uint256) {

68:     function votingPeriod() public view override returns (uint256) {

74:     function proposalThreshold() public view override returns (uint256) {

81:     function setProposalThresholdPercentage(uint32 _proposalThresholdPercentage) public {

90:     function setVotingPeriod(uint32 _votingPeriodInSeconds) public {

100:     function setVotingDelay(uint32 _votingDelayInSeconds) public {

114:     function state(uint256 proposalId) public view override(Governor) returns (ProposalState) {

120:     function proposalNeedsQueuing(uint256 proposalId) public view virtual override(Governor) returns (bool) {

156:     function _executor() internal view override(Governor) returns (address) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)

### <a name="NC-8"></a>[NC-8] Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor
If a function is supposed to be access-controlled, a `modifier` should be used instead of a `require/if` statement for more readability.

*Instances (6)*:
```solidity
File: /src/Agent.sol

37:         if (msg.sender != address(factory)) revert NotFactory();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

347:         if (msg.sender == owner() || (msg.sender == agentManager[_agent] && _stage == 1)) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/BootstrapPool.sol

50:         if (msg.sender != owner) revert NotOwner();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/TokenGovernor.sol

82:         if (msg.sender != address(this)) revert NotGovernor();

91:         if (msg.sender != address(this)) revert NotGovernor();

101:         if (msg.sender != address(this)) revert NotGovernor();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)

### <a name="NC-9"></a>[NC-9] Consider using named mappings
Consider moving to solidity version 0.8.18 or later, and using [named mappings](https://ethereum.stackexchange.com/questions/51629/how-to-name-the-arguments-in-mapping/145555#145555) to make it easier to understand the purpose of each mapping

*Instances (3)*:
```solidity
File: /src/AgentFactory.sol

51:     mapping(address => address) public agentManager;

53:     mapping(address => address) public tokenAgent;

63:     mapping(address => bool) public allowedProxyImplementation;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

### <a name="NC-10"></a>[NC-10] `address`s shouldn't be hard-coded
It is often better to declare `address`es as `immutable`, and assign them via constructor arguments. This allows the code to remain the same across deployments on different networks, and avoids recompilation when addresses need to change.

*Instances (3)*:
```solidity
File: /src/AgentRouter.sol

35:     IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

```solidity
File: /src/LiquidityManager.sol

54:     IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);

56:     IBAMMFactory public constant bammFactory = IBAMMFactory(0x19928170D739139bfbBb6614007F8EEeD17DB0Ba);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="NC-11"></a>[NC-11] Take advantage of Custom Error's return value property
An important feature of Custom Error is that values such as address, tokenID, msg.value can be written inside the () sign, this kind of approach provides a serious advantage in debugging and examining the revert details of dapps such as tenderly.

*Instances (25)*:
```solidity
File: /src/AIToken.sol

84:             revert ERC6372InconsistentClock();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

37:         if (msg.sender != address(factory)) revert NotFactory();

42:         if (stage == 0) revert NotAlive();

97:             revert InvalidProxyImplementation();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

267:             revert TradingFeeTooHigh();

295:             revert ShareToBammTooHigh();

307:             revert MintTODAOTooHigh();

319:             revert MintToAgentTooHigh();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/AgentRouter.sol

68:         if (agent == address(0)) revert AgentNotFound();

88:         if (_amountOut < _minAmountOut) revert InsufficientAmountOut();

109:         if (agent == address(0)) revert AgentNotFound();

129:         if (_amountOut < _minAmountOut) revert InsufficientAmountOut();

142:             if (agent == address(0)) revert AgentNotFound();

158:             if (agent == address(0)) revert AgentNotFound();

171:             revert NoCurrencyToken();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

```solidity
File: /src/BootstrapPool.sol

45:         if (killed) revert BootstrapPoolKilled();

50:         if (msg.sender != owner) revert NotOwner();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/TokenGovernor.sol

82:         if (msg.sender != address(this)) revert NotGovernor();

83:         if (proposalThresholdPercentage > 1000) revert InvalidThreshold(); // Max 10%

91:         if (msg.sender != address(this)) revert NotGovernor();

92:         if (_votingPeriodInSeconds > 30 days) revert InvalidPeriod(); // Max 30 days

93:         if (_votingPeriodInSeconds < 3 days) revert InvalidPeriod(); // Min 3 days

101:         if (msg.sender != address(this)) revert NotGovernor();

102:         if (_votingDelayInSeconds > 7 days) revert InvalidDelay(); // Max 7 days

103:         if (_votingDelayInSeconds < 12 hours) revert InvalidDelay(); // Min 12 hours

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)

### <a name="NC-12"></a>[NC-12] Use scientific notation (e.g. `1e18`) rather than exponentiation (e.g. `10**18`)
While this won't save gas in the recent solidity versions, this is shorter and more readable (this is especially true in calculations).

*Instances (1)*:
```solidity
File: /src/AIToken.sol

21: uint256 constant INITAL_SUPPLY = 100_000_000 * 10 ** 18;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

### <a name="NC-13"></a>[NC-13] Use Underscores for Number Literals (add an underscore every 3 digits)

*Instances (2)*:
```solidity
File: /src/AgentFactory.sol

317:         if (_mintToAgent > 2000) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/TokenGovernor.sol

83:         if (proposalThresholdPercentage > 1000) revert InvalidThreshold(); // Max 10%

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)

### <a name="NC-14"></a>[NC-14] Variables need not be initialized to zero
The default value for variables is zero, so initializing them to zero is superfluous.

*Instances (2)*:
```solidity
File: /src/Agent.sol

33:     uint256 public stage = 0;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/LiquidityManager.sol

158:             for (uint256 i = 0; i < 3; ++i) {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)


## Low Issues


| |Issue|Instances|
|-|:-|:-:|
| [L-1](#L-1) | `approve()`/`safeApprove()` may revert if the current approval is not zero | 2 |
| [L-2](#L-2) | Use a 2-step ownership transfer pattern | 2 |
| [L-3](#L-3) | Division by zero not prevented | 6 |
| [L-4](#L-4) | Possible rounding issue | 3 |
| [L-5](#L-5) | Loss of precision | 3 |
| [L-6](#L-6) | Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership` | 4 |
| [L-7](#L-7) | Sweeping may break accounting if tokens with multiple addresses are used | 5 |
| [L-8](#L-8) | Unsafe ERC20 operation(s) | 5 |
| [L-9](#L-9) | Unspecific compiler version pragma | 7 |
| [L-10](#L-10) | Upgradeable contract not initialized | 7 |
### <a name="L-1"></a>[L-1] `approve()`/`safeApprove()` may revert if the current approval is not zero
- Some tokens (like the *very popular* USDT) do not work when changing the allowance from an existing non-zero allowance value (it will revert if the current approval is not zero to protect against front-running changes of approvals). These tokens must first be approved for zero and then the actual allowance can be approved.
- Furthermore, OZ's implementation of safeApprove would throw an error if an approve is attempted from a non-zero value (`"SafeERC20: approve from non-zero to non-zero allowance"`)

Set the allowance to zero immediately before each of the existing allowance calls

*Instances (2)*:
```solidity
File: /src/AgentFactory.sol

124:             currencyToken.approve(address(manager.bootstrapPool()), _amountToBuy);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/LiquidityManager.sol

216:             fraxswapPair.approve(address(bamm), amountToBamm);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="L-2"></a>[L-2] Use a 2-step ownership transfer pattern
Recommend considering implementing a two step process where the owner or admin nominates an account and the nominated account needs to call an `acceptOwnership()` function for the transfer of ownership to fully succeed. This ensures the nominated EOA account is a valid and active account. Lack of two-step procedure for critical operations leaves them error-prone. Consider adding two step procedure on the critical functions.

*Instances (2)*:
```solidity
File: /src/AIToken.sol

27: contract AIToken is ERC20Votes, ERC20Permit, Ownable {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

25: contract Agent is ERC721URIStorage, Ownable, Proxy {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

### <a name="L-3"></a>[L-3] Division by zero not prevented
The divisions below take an input parameter which does not have any zero-value checks, which may lead to the functions reverting when zero is passed.

*Instances (6)*:
```solidity
File: /src/BootstrapPool.sol

127:         _price = (_reserveCurrencyToken * 1e18) / _reserveAgentToken;

154:         _amountOut = _numerator / _denominator;

172:         _amountIn = _numerator / _denominator;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

117:         uint256 liquidityAmount = (currencyAmount * 1e18) / price;

171:                 if ((currencyAmount * uint256(reserveAgentTokens)) / uint256(reserveCurrency) > liquidityAmount) {

240:         if (prod > minus) maxSell = (prod - minus) / (reserveOut + tokenOut);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="L-4"></a>[L-4] Possible rounding issue
Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator. Also, there is indication of multiplication and division without the use of parenthesis which could result in issues.

*Instances (3)*:
```solidity
File: /src/BootstrapPool.sol

127:         _price = (_reserveCurrencyToken * 1e18) / _reserveAgentToken;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

171:                 if ((currencyAmount * uint256(reserveAgentTokens)) / uint256(reserveCurrency) > liquidityAmount) {

240:         if (prod > minus) maxSell = (prod - minus) / (reserveOut + tokenOut);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="L-5"></a>[L-5] Loss of precision
Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator

*Instances (3)*:
```solidity
File: /src/BootstrapPool.sol

127:         _price = (_reserveCurrencyToken * 1e18) / _reserveAgentToken;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

171:                 if ((currencyAmount * uint256(reserveAgentTokens)) / uint256(reserveCurrency) > liquidityAmount) {

240:         if (prod > minus) maxSell = (prod - minus) / (reserveOut + tokenOut);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="L-6"></a>[L-6] Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership`
Use [Ownable2Step.transferOwnership](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol) which is safer. Use it as it is more secure due to 2-stage ownership transfer.

**Recommended Mitigation Steps**

Use <a href="https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol">Ownable2Step.sol</a>
  
  ```solidity
      function acceptOwnership() external {
          address sender = _msgSender();
          require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
          _transferOwnership(sender);
      }
```

*Instances (4)*:
```solidity
File: /src/AIToken.sol

4: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

5: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

6: import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

100:         agent.transferOwnership(address(governance));

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

### <a name="L-7"></a>[L-7] Sweeping may break accounting if tokens with multiple addresses are used
There have been [cases](https://blog.openzeppelin.com/compound-tusd-integration-issue-retrospective/) in the past where a token mistakenly had two addresses that could control its balance, and transfers using one address impacted the balance of the other. To protect against this potential scenario, sweep functions should ensure that the balance of the non-sweepable token does not change after the transfer of the swept tokens.

*Instances (5)*:
```solidity
File: /src/AgentFactory.sol

357:     function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/BootstrapPool.sol

117:         _sweepFees();

190:     function sweepFees() public nonReentrant {

191:         _sweepFees();

195:     function _sweepFees() internal {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

### <a name="L-8"></a>[L-8] Unsafe ERC20 operation(s)

*Instances (5)*:
```solidity
File: /src/AgentFactory.sol

89:             currencyToken.transferFrom(msg.sender, address(this), creationFee);

101:         agent.transferFrom(address(this), address(governance), 0);

124:             currencyToken.approve(address(manager.bootstrapPool()), _amountToBuy);

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/LiquidityManager.sol

216:             fraxswapPair.approve(address(bamm), amountToBamm);

220:         fraxswapPair.transfer(agent, fraxswapPair.balanceOf(address(this)));

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

### <a name="L-9"></a>[L-9] Unspecific compiler version pragma

*Instances (7)*:
```solidity
File: /src/AIToken.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/AgentRouter.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentRouter.sol)

```solidity
File: /src/BootstrapPool.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

```solidity
File: /src/LiquidityManager.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)

```solidity
File: /src/TokenGovernor.sol

2: pragma solidity >=0.8.25;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/TokenGovernor.sol)

### <a name="L-10"></a>[L-10] Upgradeable contract not initialized
Upgradeable contracts are initialized via an initializer function rather than by a constructor. Leaving such a contract uninitialized may lead to it being taken over by a malicious user

*Instances (7)*:
```solidity
File: /src/Agent.sol

78:     function initializeToken(AIToken _token) public onlyOwner {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

95:         agent.initializeToken(token);

119:         manager.initializeBootstrapPool();

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/LiquidityManager.sol

37:     bool public initialized = false;

95:     function initializeBootstrapPool() external {

96:         require(!initialized, "BootstrapPool already initialized");

97:         initialized = true;

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/LiquidityManager.sol)


## Medium Issues


| |Issue|Instances|
|-|:-|:-:|
| [M-1](#M-1) | Centralization Risk for trusted owners | 26 |
### <a name="M-1"></a>[M-1] Centralization Risk for trusted owners

#### Impact:
Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

*Instances (26)*:
```solidity
File: /src/AIToken.sol

27: contract AIToken is ERC20Votes, ERC20Permit, Ownable {

38:     ) ERC20(name, symbol) ERC20Permit(name) Ownable(agent) {

56:     function mint(address to, uint256 amount) external onlyOwner {

64:     function burn(address from, uint256 amount) external onlyOwner {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AIToken.sol)

```solidity
File: /src/Agent.sol

25: contract Agent is ERC721URIStorage, Ownable, Proxy {

67:     ) ERC721(name, symbol) Ownable(_factory) {

78:     function initializeToken(AIToken _token) public onlyOwner {

95:     function setProxyImplementation(address _proxyImplementation) public onlyOwner onlyWhenAlive {

113:     function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner onlyWhenAlive {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/Agent.sol)

```solidity
File: /src/AgentFactory.sol

27: contract AgentFactory is Ownable2Step {

68:     constructor(IERC20 _currencyToken, uint256 _creationFee) Ownable(msg.sender) {

223:     function setGovenerBytecode(bytes memory _newBytecode) external onlyOwner {

231:     function setAgentBytecode(bytes memory _newBytecode) external onlyOwner {

239:     function setLiquidityManagerBytecode(bytes memory _newBytecode) external onlyOwner {

248:     function setCreationFee(uint256 _creationFee) external onlyOwner {

256:     function setCurrencyToken(IERC20 _currencyToken) external onlyOwner {

264:     function setTradingFee(uint256 _tradingFee) external onlyOwner {

275:     function setTargetCCYLiquidity(uint256 _targetCCYLiquidity) external onlyOwner {

283:     function setInitialPrice(uint256 _initialPrice) external onlyOwner {

292:     function setShareToBamm(uint256 _shareToBamm) external onlyOwner {

304:     function setMintToDAO(uint256 _mintToDAO) external onlyOwner {

316:     function setMintToAgent(uint256 _mintToAgent) external onlyOwner {

328:     function setDefaultProxyImplementation(address _defaultProxyImplementation) external onlyOwner {

337:     function setAllowedProxyImplementation(address _proxyImplementation, bool _allowed) external onlyOwner {

357:     function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/AgentFactory.sol)

```solidity
File: /src/BootstrapPool.sol

116:     function kill() external nonReentrant onlyOwner {

```
[Link to code](https://github.com/code-423n4/2025-01-iq-ai/blob/main/src/BootstrapPool.sol)

