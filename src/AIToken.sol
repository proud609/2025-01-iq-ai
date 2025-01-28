// SPDX-License-Identifier: ISC
pragma solidity >=0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

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

uint256 constant INITAL_SUPPLY = 100_000_000 * 10 ** 18;

/**
 * @title AIToken
 * @dev Implementation of the AIToken
 */
contract AIToken is ERC20Votes, ERC20Permit, Ownable {
    /// @dev Constructor
    /// @param name    The name of the `AIToken`
    /// @param symbol  The symbol of the `AIToken`
    /// @param agent   The address of the `Agent` contract
    /// @param factory The address of the `AgentFactory` contract
    constructor(
        string memory name,
        string memory symbol,
        address agent,
        address factory
    ) ERC20(name, symbol) ERC20Permit(name) Ownable(agent) {
        _mint(factory, INITAL_SUPPLY);
    }

    /// @notice Overrides base class
    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    /// @notice Overrides base class
    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    /// @notice Function which will mint tokens
    /// @param to     The address of the recipient
    /// @param amount The amount to mint
    /// @dev Only callable via owner (`Agent`)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Function which will burn tokens
    /// @param from   The address to burn from
    /// @param amount The amount to be burned
    /// @dev Only callable via owner (`Agent`)
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based
     * checkpoints (and voting), in which case {CLOCK_MODE} should be overridden as well to match.
     * This is the overridden version that uses timestamps
     */
    function clock() public view override returns (uint48) {
        return Time.timestamp();
    }

    /**
     * @dev Machine-readable description of the clock as specified in ERC-6372.
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view override returns (string memory) {
        // Check that the clock was not modified
        if (clock() != Time.timestamp()) {
            revert ERC6372InconsistentClock();
        }
        return "mode=timestamp&from=default";
    }
}
