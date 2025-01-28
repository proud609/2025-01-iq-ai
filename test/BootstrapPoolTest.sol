// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25 <0.9.0;

import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";
import {BootstrapPool} from "../src/BootstrapPool.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";
import {TokenGovernor} from "../src/TokenGovernor.sol";
import {AgentFactory} from "../src/AgentFactory.sol";
import {Agent} from "../src/Agent.sol";
import {AIToken} from "../src/AIToken.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract BootstrapPoolV1Test is Test {
    IERC20 currencyToken = IERC20(0xFc00000000000000000000000000000000000001);
    Agent agent;
    AIToken token;
    AgentFactory factory;
    BootstrapPool bootstrapPool;

    function setUpFraxtal(uint256 _block) public {
        vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"), _block);
    }

    function test_BootstrapPoolV1_unit() public {
        _bootstrapSetup();

        // Buy from the bootstrap pool
        LiquidityManager manager = LiquidityManager(factory.agentManager(address(agent)));
        bootstrapPool = manager.bootstrapPool();
        currencyToken.approve(address(bootstrapPool), 10_000_000e18);
        for (uint256 i = 0; i < 10; ++i) {
            uint256 amountIn = 1_000_000e18;
            uint256 amountOut = bootstrapPool.getAmountOut(amountIn, address(currencyToken));
            uint256 amountIn2 = bootstrapPool.getAmountIn(amountOut, address(token));
            uint256 maxSwapAmount = bootstrapPool.maxSwapAmount(address(currencyToken));
            if (maxSwapAmount == 0) break;
            if (maxSwapAmount < amountIn2) amountIn2 = maxSwapAmount;
            uint256 amountOut2 = bootstrapPool.buy(amountIn2);
            console.log("amountIn/Out 1", amountIn, amountOut);
            console.log("amountIn/Out 2", amountIn2, amountOut2);
        }
        vm.stopPrank();
    }

    function test_BootstrapPoolV1_unit2() public {
        _bootstrapSetup();

        // Buy from the bootstrap pool
        LiquidityManager manager = LiquidityManager(factory.agentManager(address(agent)));
        bootstrapPool = manager.bootstrapPool();
        currencyToken.approve(address(bootstrapPool), 10_000_000e18);
        uint256 amountIn = 1_000_000e18;
        uint256 amountOut = bootstrapPool.buy(amountIn);

        // Sell all back
        token.approve(address(bootstrapPool), amountOut);
        bootstrapPool.sell(amountOut);
        vm.stopPrank();

        // Swap agentToken from the Agent to empty the bootstrap pool
        vm.startPrank(address(agent));
        uint256 maxSwapAmount = bootstrapPool.maxSwapAmount(address(token));
        token.approve(address(bootstrapPool), maxSwapAmount);
        bootstrapPool.sell(maxSwapAmount);
        vm.stopPrank();

        // There are still enough tokens in the pool to pay out the trading fees
        bootstrapPool.sweepFees();
    }

    function test_token0() public {
        test_BootstrapPoolV1_unit();
        assertEq({
            right: address(currencyToken),
            left: bootstrapPool.token0(),
            err: "// THEN: token0 return not expected"
        });
    }

    function test_token1() public {
        test_BootstrapPoolV1_unit();
        assertEq({right: address(token), left: bootstrapPool.token1(), err: "// THEN: token1 return not expected"});
    }

    function test_bootstrapPool_killReverts() public {
        address badActor = address(0xBADBEEF);
        _bootstrapSetup();
        LiquidityManager manager = LiquidityManager(factory.agentManager(address(agent)));
        bootstrapPool = manager.bootstrapPool();

        vm.startPrank(badActor);
        vm.expectRevert(BootstrapPool.NotOwner.selector);
        bootstrapPool.kill();
    }

    function _bootstrapSetup() internal {
        setUpFraxtal(12_918_968);
        address whale = 0x00160baF84b3D2014837cc12e838ea399f8b8478;
        factory = new AgentFactory(currencyToken, 0);
        factory.setAgentBytecode(type(Agent).creationCode);
        factory.setGovenerBytecode(type(TokenGovernor).creationCode);
        factory.setLiquidityManagerBytecode(type(LiquidityManager).creationCode);
        factory.setTargetCCYLiquidity(1000e18);
        factory.setInitialPrice(0.1e18);
        factory.setMintToAgent(1000); //10%
        vm.startPrank(whale);
        currencyToken.approve(address(factory), 1e18);
        agent = factory.createAgent("AIAgent", "AIA", "https://example.com", 0);
        token = agent.token();
    }

    function test_ownerOfToken() public {
        _bootstrapSetup();
        // console.log("The address of the agent token: ", address(agent));
        // console.log("The owner of the agentToken: ", token.owner());
        vm.startPrank(token.owner());
        token.mint(address(10), 1e18);
    }
}
