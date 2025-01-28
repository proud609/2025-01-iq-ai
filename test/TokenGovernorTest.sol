// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25 <0.9.0;

import {Test} from "forge-std/src/Test.sol";
import {console} from "forge-std/src/console.sol";
import {AgentFactory} from "../src/AgentFactory.sol";
import {TokenGovernor} from "../src/TokenGovernor.sol";
import {Agent} from "../src/Agent.sol";
import {AIToken} from "../src/AIToken.sol";
import {BootstrapPool} from "../src/BootstrapPool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";

contract TokenGovernorTest is Test {
    IERC20 currencyToken = IERC20(0xFc00000000000000000000000000000000000001);
    address whale = 0x00160baF84b3D2014837cc12e838ea399f8b8478;
    address badActor = address(0xBADBEEF);
    Agent agent;
    AIToken token;
    AgentFactory factory;
    BootstrapPool bootstrapPool;
    LiquidityManager manager;
    TokenGovernor governor;

    function setUpFraxtal(uint256 _block) public {
        vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"), _block);
    }

    function setUp() public {
        setUpFraxtal(12_918_968);
        uint256 creationFee = 15e18;
        uint256 tradingFee = 100; //1%
        uint256 initialSwap = 100e18;
        factory = new AgentFactory(currencyToken, 0);
        factory.setAgentBytecode(type(Agent).creationCode);
        factory.setGovenerBytecode(type(TokenGovernor).creationCode);
        factory.setLiquidityManagerBytecode(type(LiquidityManager).creationCode);
        factory.setTargetCCYLiquidity(1000e18);
        factory.setInitialPrice(0.1e18);
        factory.setTradingFee(tradingFee);
        factory.setCreationFee(creationFee);
        factory.setDefaultProxyImplementation(address(new DefaultProxy()));
        vm.startPrank(whale);
        currencyToken.approve(address(factory), creationFee + initialSwap);
        agent = factory.createAgent("AIAgent", "AIA", "https://example.com", initialSwap);
        token = AIToken(address(agent.token()));

        // Buy from the bootstrap pool
        manager = LiquidityManager(factory.agentManager(address(agent)));
        bootstrapPool = manager.bootstrapPool();
        currencyToken.approve(address(bootstrapPool), 10_000_000e18);
        bootstrapPool.buy(6_000_000e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        governor = TokenGovernor(payable(agent.owner()));
        console.log("votingDelay:", governor.votingDelay());
    }

    function test_AgentFactory_unit() public {
        vm.expectRevert(); // Proxy not yet set
        console.log(AirdropAgent(payable(agent)).hello());

        // Set the airdropAgentProxy implementation as allowed
        AirdropAgent airdropAgentProxy = new AirdropAgent(
            "AirdropAgent",
            "ADA",
            "https://example.com",
            address(factory)
        );
        factory.setAllowedProxyImplementation(address(airdropAgentProxy), true);

        // Set agent as alive
        factory.setAgentStage(address(agent), 1);

        address[] memory targets = new address[](1);
        targets[0] = address(agent);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("setProxyImplementation(address)", address(airdropAgentProxy));
        string memory description = "Set the airdropAgentProxy implementation";
        vm.expectRevert(); // Not the right user
        governor.propose(targets, values, calldatas, description);
        vm.startPrank(whale);
        vm.expectRevert(); // No voting power
        governor.propose(targets, values, calldatas, description);
        token.delegate(whale);
        vm.expectRevert(); // Need one block delay
        governor.propose(targets, values, calldatas, description);
        vm.warp(block.timestamp + 1);
        uint256 nonce = governor.propose(targets, values, calldatas, description);
        vm.warp(block.timestamp + governor.votingDelay() + 1);
        governor.castVote(nonce, 1);
        vm.expectRevert(); // Execution not yet ready
        governor.execute(targets, values, calldatas, keccak256(abi.encodePacked(description)));
        vm.warp(block.timestamp + governor.votingPeriod());
        governor.execute(targets, values, calldatas, keccak256(abi.encodePacked(description)));
        vm.stopPrank();
        console.log(AirdropAgent(payable(agent)).hello());
    }

    function test_initial_proposalThreshold() public view {
        uint256 initProposalThreshold = governor.proposalThreshold();
        assertEq({right: 0, left: agent.stage(), err: "// THEN: initial agent stage not expected"});
        assertEq({
            right: type(uint256).max,
            left: initProposalThreshold,
            err: "// THEN: initial proposal threshold not expected"
        });
    }

    function test_propsalThreshold() public {
        vm.prank(address(factory));
        agent.setStage(1);
        uint256 proposalThreshold = governor.proposalThreshold();
        uint256 expThreshold = (0.0001e18 * token.totalSupply()) / 1e18;
        assertEq({
            left: expThreshold,
            right: proposalThreshold,
            err: "// THEN: proposal threshold, stage > 0, not expected"
        });
    }

    function test_setProposalThreshold_reverts() public {
        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("NotGovernor()"));
        governor.setProposalThresholdPercentage(100);
    }

    function test_setVotingDelay_reverts() public {
        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("NotGovernor()"));
        governor.setVotingDelay(13 hours);
    }

    function test_setVotingPeriod_reverts() public {
        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("NotGovernor()"));
        governor.setVotingPeriod(7 days);
    }

    function test_proposalState_notExist() public {
        vm.expectRevert(abi.encodeWithSignature("GovernorNonexistentProposal(uint256)", 21));
        governor.state(21);
    }

    function test_proposalState_pending() public {
        uint256 proposalId = setUpVote();

        TokenGovernor.ProposalState state = governor.state(proposalId);

        assertEq({left: uint256(state), right: 0, err: "// THEN: propsoal is not in pending state"});
    }

    function test_proposalState_active() public {
        uint256 proposalId = setUpVote();
        vm.warp(block.timestamp + governor.votingDelay() + 1);

        TokenGovernor.ProposalState state = governor.state(proposalId);

        assertEq({left: uint256(state), right: 1, err: "// THEN: propsoal is not in pending state"});
    }

    function test_proposalNeedsQueing() public {
        uint256 proposalId = setUpVote();
        vm.warp(block.timestamp + governor.votingDelay() + 1);

        TokenGovernor.ProposalState state = governor.state(proposalId);

        vm.warp(block.timestamp + governor.votingDelay() + 1);
        governor.castVote(proposalId, 1);
        vm.warp(block.timestamp + governor.votingPeriod());

        state = governor.state(proposalId);

        bool needsQueing = governor.proposalNeedsQueuing(proposalId);
        assertEq({right: needsQueing, left: false, err: "// THEN: proposal should never need queing"});
    }

    function test_proposalCanBeCanceled() public {
        uint256 proposalId = setUpVote();
        TokenGovernor.ProposalState state = governor.state(proposalId);

        state = governor.state(proposalId);
        assertEq({left: 0, right: uint256(state), err: "// THEN: proposal should have `PENDING` state"});

        address[] memory targets = new address[](1);
        targets[0] = address(agent);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("setProxyImplementation(address)", address(77_777));
        string memory description = "Set the airdropAgentProxy implementation";

        governor.cancel(targets, values, calldatas, keccak256(abi.encodePacked(description)));

        state = governor.state(proposalId);
        assertEq({left: 2, right: uint256(state), err: "// THEN: proposal should have `CANCELED` state"});
    }

    function setUpVote() public returns (uint256 proposalId) {
        factory.setAgentStage(address(agent), 1);
        address[] memory targets = new address[](1);
        targets[0] = address(agent);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("setProxyImplementation(address)", address(77_777));
        string memory description = "Set the airdropAgentProxy implementation";
        vm.startPrank(whale);
        token.delegate(whale);
        vm.warp(block.timestamp + 1);
        proposalId = governor.propose(targets, values, calldatas, description);
    }
}

contract AirdropAgent is Agent {
    constructor(
        string memory name,
        string memory symbol,
        string memory url,
        address _factory
    ) Agent(name, symbol, url, _factory) {}

    function airdropTokens(address[] memory _recipients, uint256 _amount) public onlyOwner {
        for (uint256 i = 0; i < _recipients.length; ++i) {
            IERC20(token).transfer(_recipients[i], _amount);
        }
    }

    function hello() public pure returns (string memory) {
        return "Hello";
    }
}

contract DefaultProxy {}
