// SPDX-License-Identifier: ISC
pragma solidity ^0.8.25;

/**
 * @title IBAMM
 * @dev Minimal interface for the BAMM contract
 */
interface IBAMM {
    function mint(address to, uint256 lpIn) external returns (uint256 bammOut);
}
