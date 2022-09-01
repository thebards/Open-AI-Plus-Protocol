// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IBardsShareToken
 * @author TheBards Protocol
 * 
 * @notice This is the interface for the BardsShareToken contract.
 */
interface IBardsShareToken is IERC20Upgradeable {

    /**
     * @notice Bards Share Token Contract initializer.
     */
    function initialize() external;

    /**
     * @dev Burn tokens from an address.
     * @param _account Address from where tokens will be burned
     * @param _amount Amount of tokens to burn
     */
	function burnFrom(address _account, uint256 _amount) external;

	/**
     * @dev Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external;
	
}