// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25 <0.9.0;

import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";
import {IFraxswapPair} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol";
import {AgentFactory} from "../src/AgentFactory.sol";
import {TokenGovernor} from "../src/TokenGovernor.sol";
import {Agent} from "../src/Agent.sol";
import {AgentRouter} from "../src/AgentRouter.sol";
import {AIToken} from "../src/AIToken.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";
import {BootstrapPool} from "../src/BootstrapPool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract AgentRouterTest is Test {
    IERC20 currencyToken = IERC20(0xFc00000000000000000000000000000000000001);
    address whale = 0x00160baF84b3D2014837cc12e838ea399f8b8478;
    AgentFactory factory;
    AgentRouter router;
    AIToken token1;
    Agent agent1;
    AIToken token2;
    Agent agent2;

    function setUpFraxtal(uint256 _block) public {
        vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"), _block);
    }

    function routerSetup() public {
        factory = new AgentFactory(currencyToken, 0);
        factory.setAgentBytecode(type(Agent).creationCode);
        factory.setGovenerBytecode(type(TokenGovernor).creationCode);
        factory.setLiquidityManagerBytecode(type(LiquidityManager).creationCode);
        factory.setTargetCCYLiquidity(1000e18);
        factory.setInitialPrice(0.1e18);
        router = new AgentRouter(factory);
        agent1 = factory.createAgent("AIAgent1", "AIA1", "https://example.com", 0);
        token1 = agent1.token();
        agent2 = factory.createAgent("AIAgent2", "AIA2", "https://example.com", 0);
        token2 = agent2.token();
    }

    function test_AgentRouter() public {
        setUpFraxtal(12_918_968);
        routerSetup();

        vm.startPrank(whale);
        // Only one approve per token is needed
        currencyToken.approve(address(router), 1e70);
        token1.approve(address(router), 1e70);
        token2.approve(address(router), 1e70);

        // Do some buys and sells
        doBuysAndSells(router, token1);
        doBuysAndSells(router, token2);

        // Migrate agent1 to Fraxswap
        require(!LiquidityManager(factory.agentManager(address(agent1))).bootstrapPool().killed(), "Already killed");
        LiquidityManager(factory.agentManager(address(agent1))).moveLiquidity();
        require(LiquidityManager(factory.agentManager(address(agent1))).bootstrapPool().killed(), "Not killed");

        // Do some more buys and sells
        doBuysAndSells(router, token1);
        doBuysAndSells(router, token2);

        // Migrate agent2 to Fraxswap
        require(!LiquidityManager(factory.agentManager(address(agent2))).bootstrapPool().killed(), "Already killed");
        LiquidityManager(factory.agentManager(address(agent2))).moveLiquidity();
        require(LiquidityManager(factory.agentManager(address(agent2))).bootstrapPool().killed(), "Not killed");

        // Do even more buys and sells
        doBuysAndSells(router, token1);
        doBuysAndSells(router, token2);
        vm.stopPrank();
    }

    function doBuysAndSells(AgentRouter _router, AIToken _token) internal {
        uint256 amountOut = _router.getAmountOut(address(currencyToken), address(_token), 1_000_000e18);
        vm.expectRevert();
        _router.buy(address(_token), 1_000_000e18, amountOut + 1);
        require(_router.buy(address(_token), 1_000_000e18, amountOut) == amountOut, "Wrong amount out");
        for (uint256 i = 0; i < 5; i++) {
            uint256 amountOut2 = _router.getAmountOut(address(_token), address(currencyToken), 1000e18);
            require(_router.sell(address(_token), 1000e18, amountOut2) == amountOut2, "Wrong amount out");
        }
    }

    function test_RouterBuy() public {
        setUpFraxtal(12_918_968);
        routerSetup();

        uint256 currecnyStart = currencyToken.balanceOf(whale);
        uint256 amountOut = router.getAmountOut(address(currencyToken), address(token1), 100e18);

        vm.startPrank(whale);
        currencyToken.approve(address(router), 100e18);
        uint256 out = router.buy(address(token1), 100e18, amountOut, whale);
        vm.stopPrank();

        uint256 aiTokenEnd = token1.balanceOf(whale);

        assertEq({
            right: currecnyStart - currencyToken.balanceOf(whale),
            left: 100e18,
            err: "// THEN: currency token not sold for ai token"
        });
        assertEq({right: aiTokenEnd, left: amountOut, err: "// THEN: proceeds of buy not expected"});
        assertEq({right: amountOut, left: out, err: "// THEN: preview not equal to actual amount out"});
    }

    function test_routerSell() public {
        test_RouterBuy();

        uint256 aiTokenStart = token1.balanceOf(whale);
        uint256 currencyStart = currencyToken.balanceOf(whale);

        uint256 amountOut = router.getAmountOut(address(token1), address(currencyToken), aiTokenStart);

        vm.startPrank(whale);
        token1.approve(address(router), aiTokenStart);
        uint256 out = router.sell(address(token1), aiTokenStart, amountOut, whale);
        vm.stopPrank();

        console.log("out: ", out);

        assertEq({right: 0, left: token1.balanceOf(whale), err: "// THEN: not all tokens sold"});
        assertEq({
            right: currencyToken.balanceOf(whale) - currencyStart,
            left: amountOut,
            err: "// THEN: currencyToken increment not as expected"
        });
        assertEq({right: amountOut, left: out, err: "// THEN: preview not equal to actual amount out"});
    }
}
