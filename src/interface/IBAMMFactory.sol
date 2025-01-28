// SPDX-License-Identifier: ISC
pragma solidity ^0.8.25;

/**
 * @title IBAMMFactory
 * @dev Minimal interface for the IBAMMFactory contract
 */
interface IBAMMFactory {
    function pairToBamm(address pair) external view returns (address);
    function createBamm(address pair) external returns (address);
}
