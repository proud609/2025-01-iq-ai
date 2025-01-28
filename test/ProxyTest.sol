// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25 <0.9.0;

import {Test} from "forge-std/src/Test.sol";
import {console2} from "forge-std/src/console2.sol";
import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {AgentFactory} from "../src/AgentFactory.sol";
import {TokenGovernor} from "../src/TokenGovernor.sol";
import {Agent} from "../src/Agent.sol";
import {AIToken} from "../src/AIToken.sol";
import {LiquidityManager} from "../src/LiquidityManager.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract ProxyTest is Test {
    IERC20 currencyToken = IERC20(0xFc00000000000000000000000000000000000001);

    function setUpFraxtal(uint256 _block) public {
        vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"), _block);
    }

    function test_proxy() public {
        setUpFraxtal(12_918_968);
        AgentFactory factory = new AgentFactory(currencyToken, 0);
        factory.setAgentBytecode(type(Agent).creationCode);
        factory.setGovenerBytecode(type(TokenGovernor).creationCode);
        factory.setLiquidityManagerBytecode(type(LiquidityManager).creationCode);
        factory.setTargetCCYLiquidity(1000e18);
        factory.setInitialPrice(0.1e18);
        factory.setMintToAgent(1000); //10%
        factory.setDefaultProxyImplementation(address(new ProxyContract1()));
        Agent agent = factory.createAgent("AIAgent", "AIA", "https://example.com", 0);
        AIToken token = agent.token();

        console2.log(ProxyContract1(address(agent)).helloWorld());
        vm.expectRevert();
        ProxyContract2(address(agent)).test();

        // Test changing the proxy implementation, will revert
        address proxyContract = address(new ProxyContract2());
        vm.startPrank(agent.owner());
        vm.expectRevert();
        agent.setProxyImplementation(proxyContract);
        vm.stopPrank();

        // Set the new proxy implementation as allowed
        factory.setAllowedProxyImplementation(proxyContract, true);

        // Set agent as alive
        factory.setAgentStage(address(agent), 1);

        // Test changing the proxy implementation, will not revert
        vm.startPrank(agent.owner());
        agent.setProxyImplementation(proxyContract);
        vm.stopPrank();

        console2.log(ProxyContract1(address(agent)).helloWorld());
        console2.log(ProxyContract2(address(agent)).test());

        // Set the airdropAgentProxy implementation as allowed
        AirdropAgent airdropAgentProxy = new AirdropAgent(
            "AirdropAgent",
            "ADA",
            "https://example.com",
            address(factory)
        );
        factory.setAllowedProxyImplementation(address(airdropAgentProxy), true);

        vm.expectRevert();
        agent.setProxyImplementation(address(airdropAgentProxy));

        // Use the airdropAgentProxy to do an airdrop
        vm.startPrank(agent.owner());
        agent.setProxyImplementation(address(airdropAgentProxy));
        address[] memory recipients = new address[](2);
        recipients[0] = address(1);
        recipients[1] = address(2);
        vm.stopPrank();
        vm.expectRevert(); // Only owner is allowed to do the airdrop
        AirdropAgent(payable(agent)).airdropTokens(recipients, 1e18);

        // Now do the airdrop
        vm.startPrank(agent.owner());
        AirdropAgent(payable(agent)).airdropTokens(recipients, 1e18);

        // Check the airdropped balances
        require(token.balanceOf(recipients[0]) == 1e18);
        require(token.balanceOf(recipients[1]) == 1e18);
    }
}

contract ProxyContract1 {
    function helloWorld() public pure returns (string memory) {
        return "Hello world!";
    }
}

contract ProxyContract2 {
    function helloWorld() public pure returns (string memory) {
        return "Hi!";
    }

    function test() public pure returns (string memory) {
        return "This is a test!";
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
}
