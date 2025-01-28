// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25 <0.9.0;

import {Test} from "forge-std/src/Test.sol";
import {console2} from "forge-std/src/console2.sol";
import {IFraxswapPair} from "dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol";
import {AgentFactory} from "../src/AgentFactory.sol";
import {TokenGovernor} from "../src/TokenGovernor.sol";
import {Agent} from "../src/Agent.sol";
import {AIToken} from "../src/AIToken.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";
import {BootstrapPool} from "../src/BootstrapPool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract MoveLiquidityTest is Test {
    IERC20 currencyToken = IERC20(0xFc00000000000000000000000000000000000001);
    Agent agent;
    AIToken token;
    AgentFactory factory;
    BootstrapPool bootstrapPool;
    LiquidityManager manager;

    function setUpFraxtal(uint256 _block) public {
        vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"), _block);
    }

    function test_MoveLiquidityTest_unit1() public {
        moveLiquidityTest(0, 0);
    }

    function test_MoveLiquidityTest_unit2() public {
        moveLiquidityTest(10_000, 10_000);
    }

    function test_MoveLiquidityTest_unit3() public {
        moveLiquidityTest(1e18, 1e18);
    }

    function test_MoveLiquidityTest_unit4() public {
        moveLiquidityTest(2e18, 1e18);
    }

    function test_MoveLiquidityTest_unit5() public {
        moveLiquidityTest(1e18, 2e18);
    }

    function test_MoveLiquidityTest_unit6() public {
        moveLiquidityTest(100e18, 1e18);
    }

    function test_MoveLiquidityTest_unit7() public {
        moveLiquidityTest(1e18, 100e18);
    }

    function moveLiquidityTest(uint256 initialLiquidtyCurrency, uint256 initialLiquidtyToken) public {
        setUpFraxtal(12_918_968);
        address whale = 0x00160baF84b3D2014837cc12e838ea399f8b8478;
        uint256 targetCCYLiquidity = 6_100_000e18;
        factory = new AgentFactory(currencyToken, 0);
        factory.setAgentBytecode(type(Agent).creationCode);
        factory.setGovenerBytecode(type(TokenGovernor).creationCode);
        factory.setLiquidityManagerBytecode(type(LiquidityManager).creationCode);
        factory.setTargetCCYLiquidity(1000e18);
        factory.setInitialPrice(0.1e18);
        vm.startPrank(whale);
        currencyToken.approve(address(factory), 1e18);
        agent = factory.createAgent("AIAgent", "AIA", "https://example.com", 0);
        token = agent.token();

        // Buy from the bootstrap pool
        manager = LiquidityManager(factory.agentManager(address(agent)));
        bootstrapPool = manager.bootstrapPool();
        currencyToken.approve(address(bootstrapPool), 10_000_000e18);
        bootstrapPool.buy(6_000_000e18);
        for (uint256 i = 0; i < 5; i++) {
            token.approve(address(bootstrapPool), 100e18);
            bootstrapPool.sell(100e18);
        }
        for (uint256 i = 0; i < 100; i++) {
            (uint256 _reserveCurrencyToken, ) = bootstrapPool.getReserves();
            if (_reserveCurrencyToken - bootstrapPool.phantomAmount() > targetCCYLiquidity) break;
            bootstrapPool.buy(10_000e18);
        }

        if (initialLiquidtyCurrency > 0 && initialLiquidtyToken > 0) {
            // Create Fraxswappair before move
            IFraxswapPair fraxswapPair = IFraxswapPair(
                manager.fraxswapFactory().createPair(address(currencyToken), address(token), 100)
            );
            currencyToken.transfer(address(fraxswapPair), initialLiquidtyCurrency);
            token.transfer(address(fraxswapPair), initialLiquidtyToken);
            fraxswapPair.mint(address(whale));
        }

        {
            // Move liquidity
            uint256 expectedCcyTkn = currencyToken.balanceOf(address(factory)) + bootstrapPool.currencyTokenFeeEarned();
            uint256 expectedAgentTkn = token.balanceOf(address(factory)) + bootstrapPool.agentTokenFeeEarned();
            // Move liquidity
            manager.moveLiquidity();
            require(currencyToken.balanceOf(address(factory)) == expectedCcyTkn, "incorrect fees earned");
            require(token.balanceOf(address(factory)) == expectedAgentTkn, "incorrect fees earned");
        }
        {
            // Buy from the Fraxswap pool
            IFraxswapPair fraxswapPair = IFraxswapPair(
                manager.fraxswapFactory().getPair(address(currencyToken), address(token))
            );
            uint256 amountOut = fraxswapPair.getAmountOut(1e18, address(currencyToken));
            currencyToken.transfer(address(fraxswapPair), 1e18);
            if (fraxswapPair.token0() == address(currencyToken)) {
                fraxswapPair.swap(0, amountOut, address(whale), "");
            } else {
                fraxswapPair.swap(amountOut, 0, address(whale), "");
            }
        }
        vm.stopPrank();
    }

    function test_moveLiquidity_bamm() public {
        uint256 initialLiquidtyCurrency = 0;
        uint256 initialLiquidtyToken = 0;

        setUpFraxtal(13_480_110);
        address whale = 0xC4EB45d80DC1F079045E75D5d55de8eD1c1090E6;
        uint256 targetCCYLiquidity = 6_100_000e18;

        factory = new AgentFactory(currencyToken, 0);
        factory.setAgentBytecode(type(Agent).creationCode);
        factory.setGovenerBytecode(type(TokenGovernor).creationCode);
        factory.setLiquidityManagerBytecode(type(LiquidityManager).creationCode);
        factory.setShareToBamm(5000);
        factory.setTargetCCYLiquidity(targetCCYLiquidity);
        factory.setInitialPrice(0.1e18);
        vm.startPrank(whale);
        currencyToken.approve(address(factory), 1e18);
        agent = factory.createAgent("AIAgent", "AIA", "https://example.com", 0);
        token = agent.token();

        // Buy from the bootstrap pool
        manager = LiquidityManager(factory.agentManager(address(agent)));
        bootstrapPool = manager.bootstrapPool();
        currencyToken.approve(address(bootstrapPool), 10_000_000e18);
        bootstrapPool.buy(6_000_000e18);
        for (uint256 i = 0; i < 5; i++) {
            token.approve(address(bootstrapPool), 100e18);
            bootstrapPool.sell(100e18);
        }
        for (uint256 i = 0; i < 100; i++) {
            (uint256 _reserveCurrencyToken, ) = bootstrapPool.getReserves();
            if (_reserveCurrencyToken - bootstrapPool.phantomAmount() > targetCCYLiquidity) break;
            bootstrapPool.buy(10_000e18);
        }

        if (initialLiquidtyCurrency > 0 && initialLiquidtyToken > 0) {
            // Create Fraxswappair before move
            IFraxswapPair fraxswapPair = IFraxswapPair(
                manager.fraxswapFactory().createPair(address(currencyToken), address(token), 100)
            );
            currencyToken.transfer(address(fraxswapPair), initialLiquidtyCurrency);
            token.transfer(address(fraxswapPair), initialLiquidtyToken);
            fraxswapPair.mint(address(whale));
        }

        {
            // Move liquidity
            uint256 expectedCcyTkn = currencyToken.balanceOf(address(factory)) + bootstrapPool.currencyTokenFeeEarned();
            uint256 expectedAgentTkn = token.balanceOf(address(factory)) + bootstrapPool.agentTokenFeeEarned();
            // Move liquidity
            manager.moveLiquidity();
            require(currencyToken.balanceOf(address(factory)) == expectedCcyTkn, "incorrect fees earned");
            require(token.balanceOf(address(factory)) == expectedAgentTkn, "incorrect fees earned");
        }
        {
            IFraxswapPair fraxswapPair = IFraxswapPair(
                manager.fraxswapFactory().getPair(address(currencyToken), address(token))
            );
            address bamm = manager.bammFactory().pairToBamm(address(fraxswapPair));
            console2.logAddress(bamm);
            console2.log(fraxswapPair.balanceOf(bamm));
            require(fraxswapPair.balanceOf(bamm) > 10_000, "No BAMM liquidity");
        }
    }

    function test_getMaxSell() public {
        test_MoveLiquidityTest_unit1();
        uint256 result = manager.getMaxSell(2e18, 1e18, 100e18, 100e18);
        assertEq({right: 0.493830163797115618e18, left: result});
    }

    function test_moveLiquidityReverts() public {
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

        manager = LiquidityManager(factory.agentManager(address(agent)));

        vm.expectRevert(bytes("Bootstrap end-criterion not reached"));
        manager.moveLiquidity();
    }
}
