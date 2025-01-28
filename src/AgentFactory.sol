// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Agent} from "./Agent.sol";
import {AIToken} from "./AIToken.sol";
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
 * @title AgentFactory
 * @notice The AgentFactory contract is used to deploy new agents
 */
contract AgentFactory is Ownable2Step {
    using SafeERC20 for IERC20;
    using SafeERC20 for AIToken;
    /// #### Globals

    /// @notice Token to be paired w/ Agent Token
    IERC20 public currencyToken;
    /// @notice Fee, denominated in `currencyToken`, associated with creating an Agent
    uint256 public creationFee;
    /// @notice Fee to be set w/n `BootstrapPool` contract
    uint256 public tradingFee = 100; // 1%
    /// @notice The initial price set w/n `BootstrapPool` contract
    uint256 public initialPrice;
    // The target CCY liquidity
    uint256 public targetCCYLiquidity;
    // The share to Bamm on liquidity Migration
    uint256 public shareToBamm;
    /// @notice %, in 1e4, agent tokens to mint to `DAO`
    uint256 public mintToDAO;
    /// @notice %, in 1e4, agent tokens to mint to `Agent`
    uint256 public mintToAgent;
    /// @notice List of agents
    Agent[] public agents;
    /// @notice Agent to Agent Manager mapping
    mapping(address => address) public agentManager;
    /// @notice Token to Agent mapping
    mapping(address => address) public tokenAgent;
    /// @notice Agent Contract Creation code
    bytes public agentBytecode;
    /// @notice Gov Contract Creation code
    bytes public governorBytecode;
    /// @notice Liquidity Manager Creation code
    bytes public liquidityManagerBytecode;
    /// @notice Address of default impl for Agent Contract
    address public defaultProxyImplementation;
    /// @notice Mapping to check if a given implementation address is allowed
    mapping(address => bool) public allowedProxyImplementation;

    /// #### Constructor
    /// @param _currencyToken The currency token to use for the agents
    /// @param _creationFee The creation fee to deploy a new agent
    constructor(IERC20 _currencyToken, uint256 _creationFee) Ownable(msg.sender) {
        currencyToken = _currencyToken;
        creationFee = _creationFee;
    }

    /// @notice Deploy new Agent contract

    /// @notice External function to handle deployment of the `Agent` contract array
    /// @param _name        The `_name` for the agent, token and governance
    /// @param _symbol      The `_symbol` for the agent and token
    /// @param _url         The `uri` address to set w/n 721 storage w/n `Agent` contract
    /// @param _amountToBuy The _initialPrice to pass as a constructor argument
    /// @return agent The `LiquidityManager` of the agent contract created
    function createAgent(
        string memory _name,
        string memory _symbol,
        string memory _url,
        uint256 _amountToBuy
    ) external returns (Agent agent) {
        // Collect creation fee
        if (creationFee > 0) {
            currencyToken.transferFrom(msg.sender, address(this), creationFee);
        }

        // Deploy the agent
        agent = Agent(deployAgent(_name, _symbol, _url));
        AIToken token = new AIToken(string.concat(_name, " by IQ"), _symbol, address(agent), address(this));
        agent.initializeToken(token);
        tokenAgent[address(token)] = address(agent);

        // Deploy the governor
        address governance = deployGovernor(_name, address(token), address(agent));
        agent.transferOwnership(address(governance));
        agent.transferFrom(address(this), address(governance), 0);

        // Mint initial tokens and create the liquidity pool
        uint256 mintToDAOAmount = (token.totalSupply() * mintToDAO) / 10_000;
        uint256 mintToAgentAmount = (token.totalSupply() * mintToAgent) / 10_000;
        uint256 initialLiquidity = token.totalSupply() - mintToDAOAmount - mintToAgentAmount;
        LiquidityManager manager = deployLiquidityManager(
            currencyToken,
            token,
            address(agent),
            initialPrice,
            targetCCYLiquidity,
            initialLiquidity,
            tradingFee
        );
        if (mintToDAOAmount > 0) token.safeTransfer(address(this), mintToDAOAmount);
        if (mintToAgentAmount > 0) token.safeTransfer(address(agent), mintToAgentAmount);
        token.safeTransfer(address(manager), initialLiquidity);
        manager.initializeBootstrapPool();

        if (_amountToBuy > 0) {
            // Do the initial buy in name of the creator.
            currencyToken.safeTransferFrom(msg.sender, address(this), _amountToBuy);
            currencyToken.approve(address(manager.bootstrapPool()), _amountToBuy);
            manager.bootstrapPool().buy(_amountToBuy, msg.sender);
        }

        // Add the agent to the list
        agents.push(agent);
        emit AgentCreated(
            address(agent),
            address(token),
            address(agent.owner()),
            address(manager),
            address(manager.bootstrapPool())
        );
    }

    /// #### Deployers

    /// @notice Internal function to handle deploy via `create2` given the creation code in storage.
    /// @param _currencyToken      The `_currencyToken` to pass as a constructor argument
    /// @param _agentToken         The `_agentToken` to pass as a constructor argument
    /// @param _agent              The `_agent` to pass as a constructor argument
    /// @param _initialPrice       The `_initialPrice` to pass as a constructor argument
    /// @param _targetCCYLiquidity The `_targetCCYLiquidity` to pass as a constructor argument
    /// @param _initialLiquidity   The `_initialLiquidity` to pass as a constructor argument
    /// @param _fee                The `_fee` to pass as a constructor argument
    /// @return _manager The `LiquidityManager` of the agent contract created
    function deployLiquidityManager(
        IERC20 _currencyToken,
        IERC20 _agentToken,
        address _agent,
        uint256 _initialPrice,
        uint256 _targetCCYLiquidity,
        uint256 _initialLiquidity,
        uint256 _fee
    ) internal returns (LiquidityManager _manager) {
        uint256 salt = agents.length;
        bytes memory bytecodeWithArgs = abi.encodePacked(
            liquidityManagerBytecode,
            abi.encode(
                _currencyToken,
                _agentToken,
                address(this),
                _agent,
                _initialPrice,
                _targetCCYLiquidity,
                _initialLiquidity,
                _fee
            )
        );
        assembly {
            _manager := create2(0, add(bytecodeWithArgs, 0x20), mload(bytecodeWithArgs), salt)
            if iszero(extcodesize(_manager)) {
                revert(0, 0)
            }
        }
        agentManager[_agent] = address(_manager);
    }

    /// @notice Deploys a new governor
    /// @param _name      The name of the governor
    /// @param _token     The token address
    /// @param _agent     The agent address
    /// @return _governor The address of the governor
    function deployGovernor(string memory _name, address _token, address _agent) internal returns (address _governor) {
        uint256 salt = agents.length;
        bytes memory bytecodeWithArgs = abi.encodePacked(governorBytecode, abi.encode(_name, _token, _agent));
        assembly {
            _governor := create2(0, add(bytecodeWithArgs, 0x20), mload(bytecodeWithArgs), salt)
            if iszero(extcodesize(_governor)) {
                revert(0, 0)
            }
        }
    }

    /// @notice Internal function to handle deploy via `create2` given the creation code in storage.
    /// @param name   The name to pass as a constructor argument
    /// @param symbol The symbol to pass as a constructor argument
    /// @param url    The `uri` address to set w/n 721 storage
    /// @return agentAddress The address of the agent contract created
    function deployAgent(
        string memory name,
        string memory symbol,
        string memory url
    ) internal returns (Agent agentAddress) {
        uint256 salt = agents.length;
        bytes memory bytecodeWithArgs = abi.encodePacked(agentBytecode, abi.encode(name, symbol, url, address(this)));
        assembly {
            agentAddress := create2(0, add(bytecodeWithArgs, 0x20), mload(bytecodeWithArgs), salt)
            if iszero(extcodesize(agentAddress)) {
                revert(0, 0)
            }
        }
    }

    /// #### Setters

    /// @notice Allows the owner to update the governor bytecode
    /// @param _newBytecode The creation code for the Gov contract
    /// @dev Restricted to owner
    function setGovenerBytecode(bytes memory _newBytecode) external onlyOwner {
        governorBytecode = _newBytecode;
        emit GovernorBytecodeUpdated(_newBytecode);
    }

    /// @notice Allows the owner to update the agent bytecode
    /// @param _newBytecode The creation code for the Agent contract
    /// @dev Restricted to owner
    function setAgentBytecode(bytes memory _newBytecode) external onlyOwner {
        agentBytecode = _newBytecode;
        emit AgentBytecodeUpdated(_newBytecode);
    }

    /// @notice Allows the owner to update the liquidity manager bytecode
    /// @param _newBytecode The creation code for the LiquidityManager contract
    /// @dev Restricted to owner
    function setLiquidityManagerBytecode(bytes memory _newBytecode) external onlyOwner {
        liquidityManagerBytecode = _newBytecode;
        emit LiquidityManagerBytecodeUpdated(_newBytecode);
    }

    /// @notice Sets the creation fee for `createAgent()` function call
    /// @param _creationFee The nominal amount in `currencyToken` that a user must
    ///                     pay to the `factory` on creation
    /// @dev Restricted to owner
    function setCreationFee(uint256 _creationFee) external onlyOwner {
        creationFee = _creationFee;
        emit CreationFeeSet(_creationFee);
    }

    /// @notice Sets the `currencyToken` for this factory contract
    /// @param _currencyToken The address of the token to be used as currency
    /// @dev Restricted to owner
    function setCurrencyToken(IERC20 _currencyToken) external onlyOwner {
        currencyToken = _currencyToken;
        emit CurrencyTokenSet(address(_currencyToken));
    }

    /// @notice Sets the `tradingFee` for `LiquidityManager` -> `BootstrapPool` on deploy
    /// @param _tradingFee The updated trading fee on the `BootstrapPool`
    /// @dev Restricted to owner
    function setTradingFee(uint256 _tradingFee) external onlyOwner {
        if (_tradingFee > 100) {
            // Max 1%
            revert TradingFeeTooHigh();
        }
        tradingFee = _tradingFee;
        emit TradingFeeSet(_tradingFee);
    }

    /// @notice Allows the owner to update the target CCY liquidity
    /// @param _targetCCYLiquidity The new target CCY liquidity
    function setTargetCCYLiquidity(uint256 _targetCCYLiquidity) external onlyOwner {
        targetCCYLiquidity = _targetCCYLiquidity;
        emit TargetCCYLiquiditySet(_targetCCYLiquidity);
    }

    /// @notice Sets the `initialPrice` for `LiquidityManager` -> `BootstrapPool` on deploy
    /// @param _initialPrice The new `initialPrice` to set
    /// @dev Restricted to owner
    function setInitialPrice(uint256 _initialPrice) external onlyOwner {
        initialPrice = _initialPrice;
        emit InitialPriceSet(_initialPrice);
    }

    /// @notice Sets the %, 1e4, to be seeded to FRAX BAMM on `addLiquidityToFraxswap`
    ///         w/n `LiquidityManager`. Cannot be greater than 100%
    /// @param _shareToBamm The %, in 1e4, of LP tokens to be seeded to BAMM
    /// @dev Restricted to owner
    function setShareToBamm(uint256 _shareToBamm) external onlyOwner {
        if (_shareToBamm > 10_000) {
            // Max 100%
            revert ShareToBammTooHigh();
        }
        shareToBamm = _shareToBamm;
        emit ShareToBammSet(_shareToBamm);
    }

    /// @notice Sets the %, in 1e4, to be sent to `DAO` on creation of agent token
    /// @param _mintToDAO The %, in 1e4, of `AIToken` to be sent to `DAO` on creation
    /// @dev Restricted to owner
    function setMintToDAO(uint256 _mintToDAO) external onlyOwner {
        if (_mintToDAO > 100) {
            // Max 1%
            revert MintTODAOTooHigh();
        }
        mintToDAO = _mintToDAO;
        emit MintToDAOSet(_mintToDAO);
    }

    /// @notice Sets the %, in 1e4, to be sent to `Agent` on creation of agent token
    /// @param _mintToAgent The %, in 1e4, of `AIToken` to be sent to `DAO` on creation
    /// @dev Restricted to owner
    function setMintToAgent(uint256 _mintToAgent) external onlyOwner {
        if (_mintToAgent > 2000) {
            // Max 20%
            revert MintToAgentTooHigh();
        }
        mintToAgent = _mintToAgent;
        emit MintToAgentSet(_mintToAgent);
    }

    /// @notice Sets allowed Proxy Impl on agent creation
    /// @param _defaultProxyImplementation The default implementation to fallback on the agent
    /// @dev Restricted to owner
    function setDefaultProxyImplementation(address _defaultProxyImplementation) external onlyOwner {
        defaultProxyImplementation = _defaultProxyImplementation;
        emit DefaultProxyImplementationSet(_defaultProxyImplementation);
    }

    /// @notice Sets allowed Proxy Impl w/n whitelist mappping
    /// @param _proxyImplementation The poxy address, key, in mapping
    /// @param _allowed             The intended value to said key
    /// @dev Restricted to owner
    function setAllowedProxyImplementation(address _proxyImplementation, bool _allowed) external onlyOwner {
        allowedProxyImplementation[_proxyImplementation] = _allowed;
        emit ProxyImplementationAllowed(_proxyImplementation, _allowed);
    }

    /// @notice Sets the agent stage
    /// @param _agent The address of the agent to set
    /// @param _stage The stage to set `_agent` to
    /// @dev Restricted to owner
    function setAgentStage(address _agent, uint256 _stage) external {
        if (msg.sender == owner() || (msg.sender == agentManager[_agent] && _stage == 1)) {
            Agent(payable(_agent)).setStage(_stage);
        }
    }

    /// #### Admin

    /// @notice Arbitrary Rescue functionality for the `owner` of the `AgentFactory` contract
    /// @param _tokenAddress The address of the token to rescue
    /// @param _tokenAmount The amount of token to rescue
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        // Only the owner address can ever receive the recovery withdrawal
        SafeERC20.safeTransfer(IERC20(_tokenAddress), owner(), _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    /// #### Views
    /// @notice Returns the number of agents
    /// @return The number of agents
    function numberOfAgents() external view returns (uint256) {
        return agents.length;
    }

    /// #### Events

    /// @notice Emitted when a new AIAgent is created, `createAgent()`
    /// @param agent    The address of the `Agent` contract
    /// @param token    The address of the `AIToken` contract
    /// @param governor The address of the `Gov` contract
    /// @param manager  The address of the `LiquidityManager` contract
    /// @param pool     The address of the `BootstrapPool` contract
    event AgentCreated(
        address indexed agent,
        address indexed token,
        address indexed governor,
        address manager,
        address pool
    );

    /// @notice Emitted when a new `creationFee` is set
    /// @param fee The fee denominated in `currencyToken`
    event CreationFeeSet(uint256 fee);

    /// @notice Emitted when a new `currencyToken` is set
    /// @param currencyToken The token address to set
    event CurrencyTokenSet(address currencyToken);

    /// @notice Emitted when a new `mintToDAO` is set
    /// @param mintToDAO the %, in 1e4, to be minted to tha `DAO`
    event MintToDAOSet(uint256 mintToDAO);

    /// @notice Emitted when a new `mintToAgnet` is set
    /// @param mintToAgnet the %, in 1e4, to be minted to tha `Agent`
    event MintToAgentSet(uint256 mintToAgnet);

    /// @notice Emitted when new `defaultProxyImplementation` is set
    /// @param defaultProxyImplementation new default proxy impl address
    event DefaultProxyImplementationSet(address defaultProxyImplementation);

    /// @notice Emitted when a new `proxyImplementation` is whitelisted
    /// @param proxyImplementation address, key in mapping
    /// @param allowed             bool, indicates wl status, 1 -> allowed 0 -> not
    event ProxyImplementationAllowed(address proxyImplementation, bool allowed);

    /// @notice Emitted when `Agent` creation code is changed
    /// @param newBytecode The new creation code for the `Agent` contract
    event AgentBytecodeUpdated(bytes newBytecode);

    /// @notice Emitted when `Gov` creation code is changed
    /// @param newBytecode The new creation code for the `Gov` contract
    event GovernorBytecodeUpdated(bytes newBytecode);

    /// @notice Emitted when `LiquidityManager` creation code is changed
    /// @param newBytecode The new creation code for the `LiquidityManager` contract
    event LiquidityManagerBytecodeUpdated(bytes newBytecode);

    /// @notice Emitted when the `shareToBamm` is set
    /// @param shareToBamm Share to seed bamm on migration
    event ShareToBammSet(uint256 shareToBamm);

    /// @notice Emitted when the Initial price for `BootstrapPool` creation is set
    /// @param initialPrice The price to boot strap from
    event InitialPriceSet(uint256 initialPrice);

    /// @notice Emitted when a new `targetCCYLiquidity` is set
    /// @param targetCCYLiquidity The newly set `targetCCYLiquidity` value
    event TargetCCYLiquiditySet(uint256 targetCCYLiquidity);

    /// @notice Emitted when `tradingFee` for `BootstrapPool` is set
    /// @notice The %, in 1e4, for the fees on swap w/n pool
    event TradingFeeSet(uint256 tradingFee);

    /// @notice Emitted when a token is recovered
    /// @param token  The address of the token recovered
    /// @param amount The amount of the tokens recovered
    event RecoveredERC20(address token, uint256 amount);

    /// #### Errors
    error MintTODAOTooHigh(); // Revert w/n change dao fee
    error MintToAgentTooHigh(); // Revert w/n change agent fee
    error ShareToBammTooHigh(); // Revert w/n change bamm share
    error TradingFeeTooHigh(); // Revert w/n change trading fee
}
