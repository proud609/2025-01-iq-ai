// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25 <0.9.0;

import {Agent} from "../src/Agent.sol";
import {AgentFactory} from "../src/AgentFactory.sol";
import {TokenGovernor} from "../src/TokenGovernor.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";
import {AIToken} from "../src/AIToken.sol";
import {AgentRouter} from "../src/AgentRouter.sol";
import {BootstrapPool} from "../src/BootstrapPool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {BaseScript} from "./Base.s.sol";

address constant IQ = 0x6EFB84bda519726Fa1c65558e520B92b51712101;
address constant IQ_TEST = 0xCc3023635dF54FC0e43F47bc4BeB90c3d1fbDa9f;
address constant DEPLOYER = 0x9fEAB70f3c4a944B97b7565BAc4991dF5B7A69ff;

contract Deploy is BaseScript {
    function run() public broadcast returns (AgentFactory agentFactory) {
        // deploy basic contracts for verification
        address token = IQ_TEST;
        AIToken aiToken = new AIToken("IQTEST", "IQT", DEPLOYER, DEPLOYER);
        Agent agent = new Agent("IQTEST", "IQT", "https://iq.test", DEPLOYER);
        TokenGovernor governor = new TokenGovernor("IQTEST", AIToken(token), agent);
        LiquidityManager liquidityManager = new LiquidityManager(
            IERC20(token),
            AIToken(token),
            DEPLOYER,
            DEPLOYER,
            0.1e18,
            100,
            1e16,
            1e20
        );
        BootstrapPool pool = new BootstrapPool(IERC20(token), IERC20(token), 0.0125e18, 1000 ether, 100);

        // main deployment
        agentFactory = new AgentFactory(IERC20(token), 1000 ether); // TODO: change to IQ
        agentFactory.setAgentBytecode(type(Agent).creationCode);
        agentFactory.setGovenerBytecode(type(TokenGovernor).creationCode);
        agentFactory.setLiquidityManagerBytecode(type(LiquidityManager).creationCode);
        agentFactory.setTargetCCYLiquidity(5_900_000e18);
        agentFactory.setInitialPrice(0.05e18);
        agentFactory.setMintToAgent(1000);
        agentFactory.setTradingFee(100);

        AgentRouter router = new AgentRouter(agentFactory);
    }
}
