// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {AIToken} from "./AIToken.sol";
import {AgentFactory} from "./AgentFactory.sol";

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
 * @title Agent
 * @dev Agent contract
 */
contract Agent is ERC721URIStorage, Ownable, Proxy {
    // The AIToken contract associated with this agent
    AIToken public token;
    // The AgentFactory contract from which `Agent` is deployed
    AgentFactory public immutable factory;
    // The address of the proxy implementation set by the agent governance
    address public proxyImplementation;
    // The stage of the agent
    uint256 public stage = 0;

    // Modifiers
    modifier onlyFactory() {
        if (msg.sender != address(factory)) revert NotFactory();
        _;
    }

    modifier onlyWhenAlive() {
        if (stage == 0) revert NotAlive();
        _;
    }

    // Errors
    error InvalidTargetAddress();
    error InvalidProxyImplementation();
    error NotFactory();
    error NotAlive();

    // Events
    event ProxyImplementationSet(address _proxyImplementation);
    event TokenURISet(uint256 indexed tokenId, string _tokenURI);
    event StageSet(uint256 _stage);

    /// @dev Constructor
    /// @param name     The name of the agent
    /// @param symbol   The symbol of the agent
    /// @param url      The URL of the agent
    /// @param _factory The address of the AgentFactory contract
    constructor(
        string memory name,
        string memory symbol,
        string memory url,
        address _factory
    ) ERC721(name, symbol) Ownable(_factory) {
        factory = AgentFactory(_factory);
        _mint(_factory, 0);
        _setTokenURI(0, url);
    }

    /// @dev Fallback function to receive the gas token
    receive() external payable {}

    /// @dev Initialize the token, can only be set once by the owner
    /// @param _token The address of the AIToken contract
    function initializeToken(AIToken _token) public onlyOwner {
        if (token == AIToken(address(0))) token = _token;
    }

    /// @dev Returns the implementation address of the proxy
    function _implementation() internal view override returns (address) {
        // If the proxy implementation is set, return it
        if (proxyImplementation != address(0)) {
            return proxyImplementation;
        } else {
            // Otherwise, return the default proxy implementation from the factory
            return factory.defaultProxyImplementation();
        }
    }

    /// @dev set the proxy implementation address
    /// @param _proxyImplementation The address of the proxy implementation
    function setProxyImplementation(address _proxyImplementation) public onlyOwner onlyWhenAlive {
        if (_proxyImplementation != address(0) && !factory.allowedProxyImplementation(_proxyImplementation)) {
            revert InvalidProxyImplementation();
        }
        proxyImplementation = _proxyImplementation;
        emit ProxyImplementationSet(_proxyImplementation);
    }

    /// @dev set the stage of the agent
    /// @param _stage The stage of the agent
    function setStage(uint256 _stage) public onlyFactory {
        if (_stage > stage) stage = _stage;
        emit StageSet(_stage);
    }

    /// @dev set the token URI
    /// @param tokenId   The token ID
    /// @param _tokenURI The token URI
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner onlyWhenAlive {
        _setTokenURI(tokenId, _tokenURI);
        emit TokenURISet(tokenId, _tokenURI);
    }
}
