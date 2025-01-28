// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AgentFactory} from "./AgentFactory.sol";
import {LiquidityManager} from "./LiquidityManager.sol";
import {BootstrapPool} from "./BootstrapPool.sol";
import {IFraxswapPair} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol";
import {IFraxswapFactory} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol";

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
 * @title AgentRouter
 * @dev AgentRouter contract
 */
contract AgentRouter {
    using SafeERC20 for IERC20;

    // The AgentFactory contract
    AgentFactory public factory;
    // The currency token
    IERC20 public currencyToken;
    // The Fraxswap factory
    IFraxswapFactory public constant fraxswapFactory = IFraxswapFactory(0xE30521fe7f3bEB6Ad556887b50739d6C7CA667E6);

    /// #### Errors
    error AgentNotFound();
    error NoCurrencyToken();
    error InsufficientAmountOut();

    /// @dev Constructor
    /// @param _factory The address of the AgentFactory contract
    constructor(AgentFactory _factory) {
        factory = _factory;
        currencyToken = _factory.currencyToken();
    }

    /// @dev Buy agent token
    /// @param _agentToken The address of the agent token to buy
    /// @param _amountIn   The amount of currency token to spend
    function buy(address _agentToken, uint256 _amountIn, uint256 _minAmountOut) external returns (uint256 _amountOut) {
        _amountOut = buy(_agentToken, _amountIn, _minAmountOut, msg.sender);
    }

    /// @dev Buy agent token
    /// @param _agentToken The address of the agent token to buy
    /// @param _amountIn   The amount of currency token to spend
    /// @param _recipient  The recipient of the agent token
    function buy(
        address _agentToken,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _recipient
    ) public returns (uint256 _amountOut) {
        // Find the bootstrap pool of the agent token
        address agent = factory.tokenAgent(_agentToken);
        if (agent == address(0)) revert AgentNotFound();
        LiquidityManager liquidityManager = LiquidityManager(factory.agentManager(agent));
        BootstrapPool bootstrapPool = liquidityManager.bootstrapPool();
        // If the bootstrap pool is not killed, buy the agent token from the bootstrap pool
        if (!bootstrapPool.killed()) {
            currencyToken.safeTransferFrom(msg.sender, address(this), _amountIn);
            currencyToken.forceApprove(address(bootstrapPool), _amountIn);
            _amountOut = bootstrapPool.buy(_amountIn, _recipient);
        } else {
            // Otherwise, buy the agent token from Fraxswap
            IFraxswapPair fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(address(currencyToken), _agentToken));
            fraxswapPair.sync();
            _amountOut = fraxswapPair.getAmountOut(_amountIn, address(currencyToken));
            currencyToken.safeTransferFrom(msg.sender, address(fraxswapPair), _amountIn);
            if (fraxswapPair.token0() == address(currencyToken)) {
                fraxswapPair.swap(0, _amountOut, _recipient, "");
            } else {
                fraxswapPair.swap(_amountOut, 0, _recipient, "");
            }
        }
        if (_amountOut < _minAmountOut) revert InsufficientAmountOut();
    }

    /// @dev Sell agent token
    /// @param _agentToken The address of the agent token to sell
    /// @param _amountIn   The amount of agent token to sell
    function sell(address _agentToken, uint256 _amountIn, uint256 _minAmountOut) external returns (uint256 _amountOut) {
        _amountOut = sell(_agentToken, _amountIn, _minAmountOut, msg.sender);
    }

    /// @dev Sell agent token
    /// @param _agentToken The address of the agent token to sell
    /// @param _amountIn   The amount of agent token to sell
    function sell(
        address _agentToken,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _recipient
    ) public returns (uint256 _amountOut) {
        // Find the bootstrap pool of the agent token
        address agent = factory.tokenAgent(_agentToken);
        if (agent == address(0)) revert AgentNotFound();
        LiquidityManager liquidityManager = LiquidityManager(factory.agentManager(agent));
        BootstrapPool bootstrapPool = liquidityManager.bootstrapPool();
        // If the bootstrap pool is not killed, sell the agent token to the bootstrap pool
        if (!bootstrapPool.killed()) {
            IERC20(_agentToken).safeTransferFrom(msg.sender, address(this), _amountIn);
            IERC20(_agentToken).forceApprove(address(bootstrapPool), _amountIn);
            _amountOut = bootstrapPool.sell(_amountIn, _recipient);
        } else {
            // Otherwise, sell the agent token to Fraxswap
            IFraxswapPair fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(address(currencyToken), _agentToken));
            fraxswapPair.sync();
            _amountOut = fraxswapPair.getAmountOut(_amountIn, _agentToken);
            IERC20(_agentToken).safeTransferFrom(msg.sender, address(fraxswapPair), _amountIn);
            if (fraxswapPair.token0() == address(_agentToken)) {
                fraxswapPair.swap(0, _amountOut, _recipient, "");
            } else {
                fraxswapPair.swap(_amountOut, 0, _recipient, "");
            }
        }
        if (_amountOut < _minAmountOut) revert InsufficientAmountOut();
    }

    /// @dev Get the amount of token you get given the amount of token you spend
    /// @dev Must be called via a static call, because it calls sync in the Fraxswap pair.
    /// @param _tokenIn  The address of the token you spend
    /// @param _tokenOut The address of the token you get
    /// @param _amountIn The amount of token you spend
    function getAmountOut(address _tokenIn, address _tokenOut, uint256 _amountIn) external returns (uint256) {
        // If the token you spend is the currency token
        if (_tokenIn == address(currencyToken)) {
            /// find the bootstrap pool of the token you get
            address agent = factory.tokenAgent(_tokenOut);
            if (agent == address(0)) revert AgentNotFound();
            LiquidityManager liquidityManager = LiquidityManager(factory.agentManager(agent));
            BootstrapPool bootstrapPool = liquidityManager.bootstrapPool();
            // If the bootstrap pool is not killed, get the amount of token you get from the bootstrap pool
            if (!bootstrapPool.killed()) {
                return bootstrapPool.getAmountOut(_amountIn, _tokenIn);
            } else {
                // Otherwise, get the amount of token you get from Fraxswap
                IFraxswapPair fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(_tokenIn, _tokenOut));
                fraxswapPair.sync();
                return fraxswapPair.getAmountOut(_amountIn, _tokenIn);
            }
        } else if (_tokenOut == address(currencyToken)) {
            // If the token you get is the currency token
            // Find the bootstrap pool of the token you spend
            address agent = factory.tokenAgent(_tokenIn);
            if (agent == address(0)) revert AgentNotFound();
            LiquidityManager liquidityManager = LiquidityManager(factory.agentManager(agent));
            BootstrapPool bootstrapPool = liquidityManager.bootstrapPool();
            // If the bootstrap pool is not killed, get the amount of token you get from the bootstrap pool
            if (!bootstrapPool.killed()) {
                return bootstrapPool.getAmountOut(_amountIn, _tokenIn);
            } else {
                // Otherwise, get the amount of token you get from Fraxswap
                IFraxswapPair fraxswapPair = IFraxswapPair(fraxswapFactory.getPair(_tokenIn, _tokenOut));
                fraxswapPair.sync();
                return fraxswapPair.getAmountOut(_amountIn, _tokenIn);
            }
        } else {
            revert NoCurrencyToken();
        }
    }
}
