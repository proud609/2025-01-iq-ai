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
import {AIToken, ERC20Permit} from "../src/AIToken.sol";
import {SigUtils} from "test/Helpers/SigUtils.sol";

contract AITokenTest is Test {
    address alice = address(0xA11ce);
    address bob = address(0xB0B);
    address badActor = address(0x77777);

    uint256 sigPk = 0xFFFFF115;
    address sigTester;
    SigUtils sigUtils;

    TokenGovernor governor;
    AIToken aiToken;
    IERC20 currencyToken = IERC20(0xFc00000000000000000000000000000000000001);
    address whale = 0x00160baF84b3D2014837cc12e838ea399f8b8478;
    uint256 constant TEST_BLOCK = 0;
    uint256 startingAiBalance;

    function setUpFraxtal(uint256 _block) public {
        if (_block == 0) vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"));
        else vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"), _block);
    }

    function setUp() public {
        setUpFraxtal(TEST_BLOCK);
        uint256 creationFee = 15e18;
        uint256 tradingFee = 100; //1%
        uint256 initialSwap = 100e18;
        AgentFactory factory = new AgentFactory(currencyToken, 0);
        factory.setAgentBytecode(type(Agent).creationCode);
        factory.setGovenerBytecode(type(TokenGovernor).creationCode);
        factory.setLiquidityManagerBytecode(type(LiquidityManager).creationCode);
        factory.setTargetCCYLiquidity(1000e18);
        factory.setInitialPrice(0.1e18);
        factory.setTradingFee(tradingFee);
        factory.setCreationFee(creationFee);
        // factory.setDefaultProxyImplementation(address(new DefaultProxy()));
        vm.startPrank(whale);
        currencyToken.approve(address(factory), creationFee + initialSwap);
        Agent agent = factory.createAgent("AIAgent", "AIA", "https://example.com", initialSwap);
        aiToken = AIToken(address(agent.token()));

        // Buy from the bootstrap pool
        LiquidityManager manager = LiquidityManager(factory.agentManager(address(agent)));
        BootstrapPool bootstrapPool = manager.bootstrapPool();
        currencyToken.approve(address(bootstrapPool), 10_000_000e18);
        bootstrapPool.buy(6_000_000e18);
        vm.stopPrank();

        startingAiBalance = aiToken.balanceOf(whale);

        vm.warp(block.timestamp + 1);
    }

    function test_log_aiToken() public {
        console.log(address(aiToken));
        console.log(aiToken.balanceOf(whale));
    }

    function test_clockMode() public {
        string memory result = aiToken.CLOCK_MODE();
        console.log(result);
        assertEq({left: "mode=timestamp&from=default", right: result, err: "// THEN: Clock mode not expected"});
    }

    function test_permit_nonces() public {
        initSigTester();
        uint256 initialNonce = aiToken.nonces(sigTester);
        assertEq({right: 0, left: initialNonce, err: "// THEN: initial nonce not expected"});

        vm.prank(whale);
        aiToken.transfer(sigTester, 5e18);

        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: sigTester,
            spender: bob,
            value: 5e18,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });
        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sigPk, digest);
        aiToken.permit(sigTester, bob, 5e18, block.timestamp + 1 days, v, r, s);

        assertEq({
            right: aiToken.nonces(sigTester),
            left: initialNonce + 1,
            err: "// THEN: permit increment not as expected"
        });

        vm.prank(bob);
        aiToken.transferFrom(sigTester, bob, 5e18);
        console.log(aiToken.balanceOf(bob));
        assertEq({right: aiToken.balanceOf(sigTester), left: 0, err: "// THEN: aiToken balance not expected"});
        assertEq({right: aiToken.balanceOf(bob), left: 5e18, err: "// THEN: aiToken balance not expected"});
    }

    function test_mintNotOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        aiToken.mint(badActor, 100e18);
    }

    function test_burnNotOwner() public {
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        vm.prank(badActor);
        aiToken.burn(whale, 100e18);
    }

    function test_mint() public {
        uint256 tsPre = aiToken.totalSupply();
        vm.prank(aiToken.owner());
        aiToken.mint(address(bob), 100e18);
        uint256 tsPost = aiToken.totalSupply();
        assertEq({left: aiToken.balanceOf(bob), right: 100e18, err: "// THEN: bob not minted expected tokens"});
        assertEq({left: tsPost - tsPre, right: 100e18, err: "// THEN: token total supply increase not expected"});
    }

    function test_burn() public {
        uint256 tsPre = aiToken.totalSupply();
        vm.prank(aiToken.owner());
        aiToken.burn(whale, 100e18);
        uint256 tsPost = aiToken.totalSupply();
        assertEq({
            left: aiToken.balanceOf(whale),
            right: startingAiBalance - 100e18,
            err: "// THEN: whales balance decrement not expected"
        });
        assertEq({left: tsPre - tsPost, right: 100e18, err: "// THEN: token total supply decrement not expected"});
    }

    function test_cannot_burn_more_than_balance() public {
        vm.prank(aiToken.owner());
        vm.expectRevert(abi.encodeWithSignature("ERC20InsufficientBalance(address,uint256,uint256)", bob, 0, 100e18));
        aiToken.burn(bob, 100e18);
    }

    function test_availableVotes_changeMintAndBurn() public {
        vm.prank(whale);
        aiToken.delegate(whale);

        uint256 startingVotes = aiToken.getVotes(whale);
        assertEq({left: startingVotes, right: aiToken.balanceOf(whale), err: "// THEN: starting Vote !eq balance"});

        vm.prank(aiToken.owner());
        aiToken.mint(whale, 69_000_000e18);

        assertEq({
            left: startingVotes + 69_000_000e18,
            right: aiToken.getVotes(whale),
            err: "// THEN: Vote balance not incremented"
        });

        vm.prank(aiToken.owner());
        aiToken.burn(whale, 69_000_000e18);

        assertEq({left: startingVotes, right: aiToken.getVotes(whale), err: "// THEN: Vote balance not decremented"});
    }

    function initSigTester() public {
        sigUtils = new SigUtils(ERC20Permit(address(aiToken)).DOMAIN_SEPARATOR());
        sigTester = vm.addr(sigPk);
    }
}
