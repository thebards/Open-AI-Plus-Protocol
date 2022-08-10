// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IBardsShareToken
 * @author TheBards Protocol
 * 
 * @notice This is the interface for the BardsShareToken contract.
 */
interface IBardsShareToken {

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