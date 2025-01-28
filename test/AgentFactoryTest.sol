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
        setUpFraxtal(0);
        factory = new AgentFactory(currencyToken, 0);
    }

    function test_AgentFactory_unit() public {
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

        require(currencyToken.balanceOf(address(factory)) == creationFee, "Creation fee incorrect");
        require(
            currencyToken.balanceOf(address(LiquidityManager(factory.agentManager(address(agent))).bootstrapPool())) ==
                initialSwap,
            "Initial swap incorrect"
        );
    }

    function test_cover() public {
        factory.setAgentBytecode(type(Agent).creationCode);
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>                   Additional Coverage                <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_canSetAgentStage() public {
        test_AgentFactory_unit();

        assertEq({right: agent.stage(), left: 0, err: "// THEN: agent stage not as expected"});

        vm.prank(badActor);
        factory.setAgentStage(address(agent), 1);

        assertEq({right: agent.stage(), left: 0, err: "// THEN: agent stage not as expected"});

        vm.prank(factory.owner());
        factory.setAgentStage(address(agent), 1);
        assertEq({right: agent.stage(), left: 1, err: "// THEN: agent stage not as expected"});
    }

    function test_owner_canTransfer() public {
        vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"));
        address owner = address(0xAD);
        vm.prank(owner);
        factory = new AgentFactory(currencyToken, 0);
        deal(address(currencyToken), address(factory), 500e18);

        assertEq({
            right: currencyToken.balanceOf(address(factory)),
            left: 500e18,
            err: "// THEN: balance of factory not as expected"
        });

        vm.prank(owner);
        factory.recoverERC20(address(currencyToken), 500e18);

        assertEq({
            right: currencyToken.balanceOf(address(factory)),
            left: 0,
            err: "// THEN: balance of factory not as expected"
        });
        assertEq({
            right: currencyToken.balanceOf(owner),
            left: 500e18,
            err: "// THEN: balance of owner not as expected"
        });
    }

    function test_setMintToDAO() public {
        assertEq({left: 0, right: factory.mintToDAO(), err: "// THEN: initial mintToDAO not expected"});

        vm.expectRevert(AgentFactory.MintTODAOTooHigh.selector);
        factory.setMintToDAO(101);

        assertEq({left: 0, right: factory.mintToDAO(), err: "// THEN: initial mintToDAO not expected"});

        vm.prank(factory.owner());
        factory.setMintToDAO(100);

        assertEq({left: 100, right: factory.mintToDAO(), err: "// THEN: initial mintToDAO not expected"});
    }

    function test_setMintToAgent() public {
        assertEq({left: 0, right: factory.mintToAgent(), err: "// THEN: initial mintToAgent not expected"});

        vm.expectRevert(AgentFactory.MintToAgentTooHigh.selector);
        factory.setMintToAgent(4000);

        assertEq({left: 0, right: factory.mintToAgent(), err: "// THEN: initial mintToDAO not expected"});

        vm.prank(factory.owner());
        factory.setMintToAgent(100);

        assertEq({left: 100, right: factory.mintToAgent(), err: "// THEN: initial mintToDAO not expected"});
    }

    function test_setCurrencyToken() public {
        address wfrxEth = 0xFC00000000000000000000000000000000000006;
        assertEq({
            left: address(currencyToken),
            right: address(factory.currencyToken()),
            err: "// THEN: initial currencyToken not expected"
        });
        vm.prank(factory.owner());
        factory.setCurrencyToken(IERC20(wfrxEth));
        assertEq({
            left: address(wfrxEth),
            right: address(factory.currencyToken()),
            err: "// THEN: initial currencyToken not expected"
        });
    }

    function test_AgentFactory_mintToAgent() public {
        setUpFraxtal(12_918_968);
        uint256 creationFee = 15e18;
        uint256 tradingFee = 100; //1%
        uint256 initialSwap = 100e18;
        address whale = 0x00160baF84b3D2014837cc12e838ea399f8b8478;
        factory = new AgentFactory(currencyToken, 0);

        factory.setMintToAgent(0.1e4); // 10%
        factory.setMintToDAO(0.001e4); // 10%

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

        require(currencyToken.balanceOf(address(factory)) == creationFee, "Creation fee incorrect");
        require(
            currencyToken.balanceOf(address(LiquidityManager(factory.agentManager(address(agent))).bootstrapPool())) ==
                initialSwap,
            "Initial swap incorrect"
        );

        IERC20 agentToken = LiquidityManager(factory.agentManager(address(agent))).agentToken();

        assertEq({
            left: (agentToken.totalSupply() * 0.1e18) / 100e18,
            right: agentToken.balanceOf(address(factory)),
            err: "// THEN: MintToDao Incorrect"
        });

        assertEq({
            left: (agentToken.totalSupply() * 10e18) / 100e18,
            right: agentToken.balanceOf(address(agent)),
            err: "// THEN: MintToAgent Incorrect"
        });
    }

    function test_max() public {
        console.log(type(uint48).max);
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>                      AC Reversions                   <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_AC_setGovenerBytecode_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setGovenerBytecode(hex"");
    }

    function test_AC_setAgentBytecode_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setAgentBytecode(hex"");
    }

    function test_AC_setLiquidityManagerBytecode_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setLiquidityManagerBytecode(hex"");
    }

    function test_AC_setCreationFee_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setCreationFee(1e36);
    }

    function test_AC_setCurrencyToken_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setCurrencyToken(IERC20(address(777)));
    }

    function test_AC_setTradingFee_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setTradingFee(1e36);
    }

    function test_AC_setTargetCCYLiquidity_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setTargetCCYLiquidity(1e36);
    }

    function test_AC_setInitialPrice_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setInitialPrice(1e36);
    }

    function test_AC_setShareToBamm_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setShareToBamm(1e36);
    }

    function test_AC_setMintToDAO_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setMintToDAO(1e36);
    }

    function test_AC_setMintToAgent_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setMintToAgent(1e36);
    }

    function test_AC_setDefaultProxyImpl_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setDefaultProxyImplementation(address(0x7777));
    }

    function test_AC_setAllowedProxyImpl_reverts_onlyOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.setAllowedProxyImplementation(address(0x7777), true);
    }

    function test_AC_transfer_reverts_onlyOwner() public {
        uint256 possibleToTransfer = currencyToken.balanceOf(address(factory));
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        factory.recoverERC20(address(currencyToken), possibleToTransfer);
    }
}
