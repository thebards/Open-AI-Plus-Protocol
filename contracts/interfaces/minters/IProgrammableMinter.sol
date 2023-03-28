// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title IMinter
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for all TheBards-compatible NFT minting modules.
 * Support any programmable NFT minting needs.
 */
interface IProgrammableMinter {


    /**
     * @notice Initializes the ProgrammableMinter, setting the initial hub address in the Minter contract.
     *
     * @param _hub The address of hub.
     */
    function initialize(
        address _hub
    ) external;

	/**
	 * @notice Mint programmable NFT.
	 * 
	 * @param metaData Meta data.
	 */
	function mint(
		bytes memory metaData
	) external returns (address, uint256);
}