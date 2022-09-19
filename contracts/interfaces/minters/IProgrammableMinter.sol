// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IMinter
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for all TheBards-compatible NFT minting modules.
 * Support any programmable NFT minting needs.
 */
interface IProgrammableMinter {

	/**
	 * @notice Mint programmable NFT.
	 * 
	 * @param metaData Meta data.
	 */
	function mint(
		bytes memory metaData
	) external returns (address, uint256);
}