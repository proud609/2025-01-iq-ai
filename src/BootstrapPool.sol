// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {LiquidityManager} from "./LiquidityManager.sol";

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
 * @title BootstrapPool
 * @dev BootstrapPool contract, the initial liquidity pool for the agent token
 */
contract BootstrapPool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // The owner of the pool
    address public immutable owner;
    // The swap fee of the pool
    uint256 public immutable fee;
    // The agent token
    IERC20 public immutable agentToken;
    // The currency token
    IERC20 public immutable currencyToken;
    // The phantom amount.
    uint256 public phantomAmount;
    // The currency token fee earned
    uint256 public currencyTokenFeeEarned;
    // The agent token fee earned
    uint256 public agentTokenFeeEarned;
    // The killed status of the pool
    bool public killed;

    modifier notKilled() {
        if (killed) revert BootstrapPoolKilled();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @dev Constructor
    /// @param _currencyToken   The currency token
    /// @param _agentToken      The agent token
    /// @param _initialPrice    The initial price of the agent token
    /// @param _bootstrapAmount The bootstrap amount of the agent token
    /// @param _fee             The swap fee of the pool
    constructor(
        IERC20 _currencyToken,
        IERC20 _agentToken,
        uint256 _initialPrice,
        uint256 _bootstrapAmount,
        uint256 _fee
    ) {
        owner = msg.sender;
        fee = 10_000 - _fee;
        currencyToken = _currencyToken;
        agentToken = _agentToken;
        phantomAmount = (_initialPrice * _bootstrapAmount) / 1e18;
    }

    /// @dev Buy agent token
    /// @param _amountIn The amount of currency token to spend
    /// @return The amount of agent token received
    function buy(uint256 _amountIn) external returns (uint256) {
        return buy(_amountIn, msg.sender);
    }

    /// @dev Buy agent token
    /// @param _amountIn  The amount of currency token to spend
    /// @param _recipient The recipient of the agent token
    /// @return The amount of agent token received
    function buy(uint256 _amountIn, address _recipient) public nonReentrant notKilled returns (uint256) {
        uint256 _amountOut = getAmountOut(_amountIn, address(currencyToken));
        currencyTokenFeeEarned += _amountIn - (_amountIn * fee) / 10_000;
        currencyToken.safeTransferFrom(msg.sender, address(this), _amountIn);
        agentToken.safeTransfer(_recipient, _amountOut);
        emit Swap(msg.sender, _amountIn, 0, 0, _amountOut, _recipient);
        return _amountOut;
    }

    /// @dev Sell agent token
    /// @param _amountIn The amount of agent token to sell
    /// @return The amount of currency token received
    function sell(uint256 _amountIn) external returns (uint256) {
        return sell(_amountIn, msg.sender);
    }

    /// @dev Sell agent token
    /// @param _amountIn  The amount of agent token to sell
    /// @param _recipient The recipient of the currency token
    /// @return The amount of currency token received
    function sell(uint256 _amountIn, address _recipient) public nonReentrant notKilled returns (uint256) {
        uint256 _amountOut = getAmountOut(_amountIn, address(agentToken));
        agentTokenFeeEarned += _amountIn - (_amountIn * fee) / 10_000;
        agentToken.safeTransferFrom(msg.sender, address(this), _amountIn);
        currencyToken.safeTransfer(_recipient, _amountOut);
        require(currencyToken.balanceOf(address(this)) >= currencyTokenFeeEarned, "INSUFFICIENT_LIQUIDITY");
        emit Swap(msg.sender, 0, _amountIn, _amountOut, 0, _recipient);
        return _amountOut;
    }

    /// @dev Kill the pool
    function kill() external nonReentrant onlyOwner {
        _sweepFees();
        killed = true;
        agentToken.safeTransfer(owner, agentToken.balanceOf(address(this)));
        currencyToken.safeTransfer(owner, currencyToken.balanceOf(address(this)));
    }

    /// @dev Get the price of the agent token in currency token
    /// @return _price The price of the agent token in currency token
    function getPrice() external view notKilled returns (uint256 _price) {
        (uint256 _reserveCurrencyToken, uint256 _reserveAgentToken) = getReserves();
        _price = (_reserveCurrencyToken * 1e18) / _reserveAgentToken;
    }

    /// @dev Get the reserves of the pool
    /// @return _reserveCurrencyToken The reserves of currency token in the pool
    /// @return _reserveAgentToken    The reserves of agent token in the pool
    function getReserves() public view returns (uint256 _reserveCurrencyToken, uint256 _reserveAgentToken) {
        _reserveCurrencyToken = phantomAmount + currencyToken.balanceOf(address(this)) - currencyTokenFeeEarned;
        _reserveAgentToken = agentToken.balanceOf(address(this)) - agentTokenFeeEarned;
    }

    /// @dev Get the amount of tokens received for a given amount of tokens
    /// @param _amountIn   The amount of tokens spent
    /// @param _tokenIn    The address of the token spent
    /// @return _amountOut The amount of tokens received
    function getAmountOut(uint256 _amountIn, address _tokenIn) public view notKilled returns (uint256 _amountOut) {
        uint256 _reserveIn;
        uint256 _reserveOut;
        if (_tokenIn == address(currencyToken)) {
            (_reserveIn, _reserveOut) = getReserves();
        } else if (_tokenIn == address(agentToken)) {
            (_reserveOut, _reserveIn) = getReserves();
        }
        require(_amountIn > 0 && _reserveIn > 0 && _reserveOut > 0); // INSUFFICIENT_INPUT_AMOUNT/INSUFFICIENT_LIQUIDITY
        uint256 _amountInWithFee = _amountIn * fee;
        uint256 _numerator = _amountInWithFee * _reserveOut;
        uint256 _denominator = (_reserveIn * 10_000) + _amountInWithFee;
        _amountOut = _numerator / _denominator;
    }

    /// @dev Get the amount of tokens spent for a given amount of tokens received
    /// @param _amountOut The amount of tokens received
    /// @param _tokenOut  The address of the token received
    /// @return _amountIn The amount of tokens spent
    function getAmountIn(uint256 _amountOut, address _tokenOut) public view notKilled returns (uint256 _amountIn) {
        uint256 _reserveIn;
        uint256 _reserveOut;
        if (_tokenOut == address(agentToken)) {
            (_reserveIn, _reserveOut) = getReserves();
        } else if (_tokenOut == address(currencyToken)) {
            (_reserveOut, _reserveIn) = getReserves();
        }
        require(_amountOut > 0 && _reserveIn > 0 && _reserveOut > 0); //INSUFFICIENT_INPUT_AMOUNT/INSUFFICIENT_LIQUIDITY
        uint256 _numerator = _amountOut * _reserveIn * 10_000;
        uint256 _denominator = (_reserveOut - _amountOut) * fee;
        _amountIn = _numerator / _denominator;
    }

    /// @dev Get the maximum amount of tokens that can be swapped
    /// @param _tokenIn   The address of the token spent
    /// @return _amountIn The maximum amount of tokens that can be swapped
    function maxSwapAmount(address _tokenIn) public view returns (uint256 _amountIn) {
        if (_tokenIn == address(currencyToken)) {
            _amountIn = type(uint256).max;
        } else if (_tokenIn == address(agentToken)) {
            _amountIn = getAmountIn(
                currencyToken.balanceOf(address(this)) - currencyTokenFeeEarned,
                address(currencyToken)
            );
        }
    }

    /// @dev Sweep the fees to liquidity manager owner
    function sweepFees() public nonReentrant {
        _sweepFees();
    }

    /// @dev Internal function to sweep the fees
    function _sweepFees() internal {
        address feeTo = LiquidityManager(owner).owner();
        currencyToken.safeTransfer(feeTo, currencyTokenFeeEarned);
        agentToken.safeTransfer(feeTo, agentTokenFeeEarned);
        currencyTokenFeeEarned = 0;
        agentTokenFeeEarned = 0;
    }

    /// @dev Returns the currency token address
    function token0() external view returns (address) {
        return address(currencyToken);
    }

    /// @dev Returns the agent token address
    function token1() external view returns (address) {
        return address(agentToken);
    }

    error BootstrapPoolKilled();
    error NotOwner();

    /// @notice Emitted when there is a swap in the pool
    /// @param sender     The `msg.sender` of the call
    /// @param amount0In  The amount of `currencyToken` in
    /// @param amount1In  The amount of `AIToken` in
    /// @param amount0Out The amount of `currencyToken` out
    /// @param amount1Out The amount of `AIToken` out
    /// @param to         The designated recipient of the swap
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
}
