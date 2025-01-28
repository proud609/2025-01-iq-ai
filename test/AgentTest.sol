// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25 <0.9.0;

import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";
import {AgentFactory} from "src/AgentFactory.sol";
import {TokenGovernor} from "src/TokenGovernor.sol";
import {Agent} from "src/Agent.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";
import {BootstrapPool} from "src/BootstrapPool.sol";

contract AgentFactoryTest is Test {
    IERC20 currencyToken = IERC20(0xFc00000000000000000000000000000000000001);
    address badActor = address(0xBADBEEF);
    AgentFactory factory;
    Agent agent;

    function setUpFraxtal(uint256 _block) public {
        if (_block == 0) vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"));
        else vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"), _block);
    }

    function setUp() public {
        setUpFraxtal(12_918_968);
        uint256 creationFee = 15e18;
        uint256 tradingFee = 100; //1%
        uint256 initialSwap = 100e18;
        address whale = 0x00160baF84b3D2014837cc12e838ea399f8b8478;
        factory = new AgentFactory(currencyToken, 0);
        factory.setAgentBytecode(type(Agent).creationCode);
        factory.setGovenerBytecode(type(TokenGovernor).creationCode);
        factory.setLiquidityManagerBytecode(type(LiquidityManager).creationCode);
        factory.setTargetCCYLiquidity(1000e18);
        factory.setInitialPrice(0.1e18);
        factory.setTradingFee(tradingFee);
        factory.setCreationFee(creationFee);
        vm.startPrank(whale);
        currencyToken.approve(address(factory), creationFee + initialSwap);
        agent = factory.createAgent("AIAgent", "AIA", "https://example.com", initialSwap);
        console.log("Initial buy", IERC20(agent.token()).balanceOf(whale));
        vm.stopPrank();
    }

    function test_setTokenUri() public {
        vm.prank(address(factory));
        agent.setStage(1);

        console.log(agent.tokenURI(0));
        string memory initialUri = agent.tokenURI(0);
        assertEq({right: initialUri, left: "https://example.com", err: "// THEN: Initial URI not expected"});
        vm.prank(agent.owner());
        agent.setTokenURI(0, "https://erikweihenmayer.com/wp-content/uploads/2021/03/uri-cover-photo-2021-2.jpg");
        string memory updatedUri = agent.tokenURI(0);
        assertEq({
            right: updatedUri,
            left: "https://erikweihenmayer.com/wp-content/uploads/2021/03/uri-cover-photo-2021-2.jpg",
            err: "// THEN: Initial URI not expected"
        });
    }

    function test_setTokenUriNotOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        agent.setTokenURI(0, "https://erikweihenmayer.com/wp-content/uploads/2021/03/uri-cover-photo-2021-2.jpg");
    }

    function test_cover_onlyWhenAlive() public {
        vm.prank(factory.owner());
        factory.setAllowedProxyImplementation(address(1), true);

        vm.prank(agent.owner());
        vm.expectRevert(Agent.NotAlive.selector);
        agent.setProxyImplementation(address(1));
    }
}
