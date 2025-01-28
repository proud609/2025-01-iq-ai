// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IFraxswapPair} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol";
import {IFraxswapFactory} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol";
import {Math} from "dev-fraxswap/src/contracts/core/libraries/Math.sol";
import {BootstrapPool} from "./BootstrapPool.sol";
import {AgentFactory} from "./AgentFactory.sol";
import {IBAMMFactory} from "./interface/IBAMMFactory.sol";
import {IBAMM} from "./interface/IBAMM.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  888   e88 88e         e Y8b                                d8           //
//  888  d888 888b       d8b Y8b     e88 888  ,e e,  888 8e   d88    dP"Y   //
//  888 C8888 8888D     d888b Y8b   d888 888 d88 88b 888 88b d88888 C88b    //
//  888  Y888 888P     d888888888b  Y888 888 888   , 888 888  888    Y88D   //
//  888   "88 88"     d8888888b Y8b  "88 888  "YeeP" 888 888  888   d,dP    //
//            b                       ,  88P                                //
//            8b,                    "8",P"                                 //
//////////////////////////////////////////////////////////////////////////////

/**
 * @title LiquidityManager
 * @dev LiquidityManager contract
 */
contract LiquidityManager {
    using SafeERC20 for IERC20;

    // The agent address
    address public immutable agent;
    // The owner of the contract
    address public immutable owner;
    // The initialized status of the contract
    bool public initialized = false;
    // The agent token
    IERC20 public immutable agentToken;
    // The currency token
    IERC20 public immutable currencyToken;
    // The bootstrap pool
    BootstrapPool public bootstrapPool;
    // The initial price of the agent token
    uint256 public immutable initialPrice;
    // The target CCY liquidity
    uint256 public immutable targetCCYLiquidity;
    // The initial liquidity
    uint256 public immutable initialLiquidity;
    // The fee
    uint256 public immutable fee;

    // The Fraxswap factory address
    IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);
    // The BAMM factory address
    IBAMMFactory public constant bammFactory = IBAMMFactory(0x19928170D739139bfbBb6614007F8EEeD17DB0Ba);

    // Events
    /// @notice Emitted on `moveLiquidity()` call
    /// @param agent       The address of the `Agent` contract being moved
    /// @param agentToken  The address of the `AIToken` contract being moved
    /// @param lpPair      The address of the V2 LP pool liquidity is moved to
    event LiquidityMoved(address indexed agent, address indexed agentToken, address indexed lpPair);

    /// @dev Constructor
    /// @param _currencyToken       The currency token
    /// @param _agentToken          The agent token
    /// @param _owner               The owner of the contract
    /// @param _agent               The agent address
    /// @param _initialPrice        The initial price of the agent token in the currency token
    /// @param _targetCCYLiquidity  The target CCY liquidity needed to move the liquidity
    /// @param _initialLiquidity    The initial liquidity of the agent token
    /// @param _fee                 The swap fee of the pool
    constructor(
        IERC20 _currencyToken,
        IERC20 _agentToken,
        address _owner,
        address _agent,
        uint256 _initialPrice,
        uint256 _targetCCYLiquidity,
        uint256 _initialLiquidity,
        uint256 _fee
    ) {
        owner = _owner;
        agent = _agent;
        currencyToken = _currencyToken;
        agentToken = _agentToken;
        initialPrice = _initialPrice;
        targetCCYLiquidity = _targetCCYLiquidity;
        initialLiquidity = _initialLiquidity;
        fee = _fee;
    }

    /// @dev Initialize the bootstrap pool, can only be called once
    function initializeBootstrapPool() external {
        require(!initialized, "BootstrapPool already initialized");
        initialized = true;
        bootstrapPool = new BootstrapPool(currencyToken, agentToken, initialPrice, initialLiquidity, fee);
        agentToken.safeTransfer(address(bootstrapPool), initialLiquidity);
    }

    /// @dev Move the liquidity from the bootstrap pool to Fraxswap
    function moveLiquidity() external {
        require(!bootstrapPool.killed(), "BootstrapPool already killed");
        uint256 price = bootstrapPool.getPrice();
        (uint256 _reserveCurrencyToken, ) = bootstrapPool.getReserves();
        _reserveCurrencyToken = _reserveCurrencyToken - bootstrapPool.phantomAmount();
        uint256 factoryTargetCCYLiquidity = AgentFactory(owner).targetCCYLiquidity();
        require(
            _reserveCurrencyToken >= targetCCYLiquidity || _reserveCurrencyToken >= factoryTargetCCYLiquidity,
            "Bootstrap end-criterion not reached"
        );
        bootstrapPool.kill();

        // Determine liquidity amount to add
        uint256 currencyAmount = currencyToken.balanceOf(address(this));
        uint256 liquidityAmount = (currencyAmount * 1e18) / price;

        // Add liquidity to Fraxswap
        IFraxswapPair fraxswapPair = addLiquidityToFraxswap(liquidityAmount, currencyAmount);

        // Send all remaining tokens to the agent.
        agentToken.safeTransfer(address(agent), agentToken.balanceOf(address(this)));
        currencyToken.safeTransfer(address(agent), currencyToken.balanceOf(address(this)));
        emit LiquidityMoved(agent, address(agentToken), address(fraxswapPair));

        AgentFactory(owner).setAgentStage(agent, 1);
    }

    /// @dev Add liquidity to Fraxswap (and BAMM)
    /// @param liquidityAmount The amount of liquidity to add
    /// @param currencyAmount  The amount of currency token to add
    function addLiquidityToFraxswap(
        uint256 liquidityAmount,
        uint256 currencyAmount
    ) internal returns (IFraxswapPair fraxswapPair) {
        fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(address(currencyToken), address(agentToken)));
        if (fraxswapPair == IFraxswapPair(address(0))) {
            // Create Fraxswap pair and add liquidity
            fraxswapPair = IFraxswapPair(fraxswapFactory.createPair(address(currencyToken), address(agentToken), fee));
            agentToken.safeTransfer(address(fraxswapPair), liquidityAmount);
            currencyToken.safeTransfer(address(fraxswapPair), currencyAmount);
            fraxswapPair.mint(address(this));
        } else {
            // Fraxswappair was already created, make sure the price in the Fraxswap pair is correct before we add
            // liquidity
            // We do a mini mint first, to make sure there are enough tokens in the pair to swap
            agentToken.safeTransfer(address(fraxswapPair), liquidityAmount / 1_000_000);
            currencyToken.safeTransfer(address(fraxswapPair), currencyAmount / 1_000_000);
            fraxswapPair.mint(address(this));
            liquidityAmount = liquidityAmount - liquidityAmount / 1_000_000;
            currencyAmount = currencyAmount - currencyAmount / 1_000_000;

            // Do three rounds of swaps to get close to the correct price.
            // We need to do this because the price in the pair is might not be the same as the price in the bootstrap
            // pool, and we need to get the price in the pair close to the price in the bootstrap pool before we add
            // liquidity. We do this in three rounds, because the swap amount calculation is not precisely correct.
            for (uint256 i = 0; i < 3; ++i) {
                uint256 reserveCurrency;
                uint256 reserveAgentTokens;
                {
                    (uint112 reserve0, uint112 reserve1, ) = fraxswapPair.getReserves();
                    if (fraxswapPair.token0() == address(currencyToken)) {
                        reserveCurrency = reserve0;
                        reserveAgentTokens = reserve1;
                    } else {
                        reserveCurrency = reserve1;
                        reserveAgentTokens = reserve0;
                    }
                }
                if ((currencyAmount * uint256(reserveAgentTokens)) / uint256(reserveCurrency) > liquidityAmount) {
                    // Swap currencyToken to agentToken
                    uint256 amountIn = getMaxSell(currencyAmount, liquidityAmount, reserveCurrency, reserveAgentTokens);
                    if (amountIn > 0) {
                        uint256 amountOut = fraxswapPair.getAmountOut(amountIn, address(currencyToken));
                        if (amountOut > 0) {
                            currencyToken.safeTransfer(address(fraxswapPair), amountIn);
                            if (fraxswapPair.token0() == address(currencyToken)) {
                                fraxswapPair.swap(0, amountOut, address(this), "");
                            } else {
                                fraxswapPair.swap(amountOut, 0, address(this), "");
                            }
                            currencyAmount -= amountIn;
                            liquidityAmount += amountOut;
                        }
                    }
                } else {
                    // Swap agentToken to the currencyToken
                    uint256 amountIn = getMaxSell(liquidityAmount, currencyAmount, reserveAgentTokens, reserveCurrency);
                    if (amountIn > 0) {
                        uint256 amountOut = fraxswapPair.getAmountOut(amountIn, address(agentToken));
                        if (amountOut > 0) {
                            agentToken.safeTransfer(address(fraxswapPair), amountIn);
                            if (fraxswapPair.token0() == address(currencyToken)) {
                                fraxswapPair.swap(amountOut, 0, address(this), "");
                            } else {
                                fraxswapPair.swap(0, amountOut, address(this), "");
                            }
                            liquidityAmount -= amountIn;
                            currencyAmount += amountOut;
                        }
                    }
                }
            }

            // Do the final mint
            agentToken.safeTransfer(address(fraxswapPair), liquidityAmount);
            currencyToken.safeTransfer(address(fraxswapPair), currencyAmount);
            fraxswapPair.mint(address(this));
        }
        uint256 amountToBamm = (fraxswapPair.balanceOf(address(this)) * AgentFactory(owner).shareToBamm()) / 10_000;
        if (amountToBamm > 0) {
            // Create BAMM pair if needed and mint BAMM LP tokens
            IBAMM bamm = IBAMM(bammFactory.pairToBamm(address(fraxswapPair)));
            if (bamm == IBAMM(address(0))) bamm = IBAMM(bammFactory.createBamm(address(fraxswapPair)));
            fraxswapPair.approve(address(bamm), amountToBamm);
            bamm.mint(agent, amountToBamm);
        }
        // Transfer remaining Fraxswap LP tokens to the agent
        fraxswapPair.transfer(agent, fraxswapPair.balanceOf(address(this)));
    }

    /// @dev Approximates how much of a token must be sold for the users ratio to be the same as the ratio in the AMM.
    /// @dev Note that this calculation ignores swap fees, so the amount is slightly lower than the correct amount.
    /// @param tokenIn    The amount of tokens we want to add as liquidity from the token we need to sell
    /// @param tokenOut   The amount of token we want to add as liquidity from the token we need to buy
    /// @param reserveIn  The current AMM reserve of the token to sell
    /// @param reserveOut The current AMM reserve of the token to buy
    /// @return maxSell   The amount of token in to sell
    function getMaxSell(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 maxSell) {
        // Solve x for: (reserveOut-y)/(reserveIn+x) = (tokenOut+y)/(tokenIn-x),
        // (reserveOut-y)*(reserveIn+x)=reserveIn*reserveOut
        uint256 prod = Math.sqrt(reserveOut * reserveIn) * Math.sqrt((reserveOut + tokenOut) * (reserveIn + tokenIn));
        uint256 minus = reserveIn * tokenOut + reserveOut * reserveIn;
        if (prod > minus) maxSell = (prod - minus) / (reserveOut + tokenOut);
    }
}
