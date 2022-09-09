// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IMarketModule
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for all TheBards-compatible NFT market modules.
 */
interface IMarketModule {
	/**
     * @notice Initializes data for a given publication being published. This can only be called by the hub.
     *
     * @param tokenContract The address of content NFT contract
     * @param tokenId The token ID of content NFT contract.
     * @param data Arbitrary data __passed from the user!__ to be decoded, such as price.
     *
     * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * hub alongside the collect module's address and should be consumed by front ends.
     */
    function initializeModule(
        address tokenContract,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes memory);

	/**
     * @notice Processes a collect action for a given NFT.
     *
     * @param collector The buyer address.
     * @param curationId The curation ID.
     * @param tokenContract The address of content NFT contract.
     * @param tokenId The token ID of content NFT contract.
     * @param curationIds the list of curation id, who act curators.
     * @param allocationIds The list of allocation id.
     * @param collectMetaData The meta data of collect.
     */
    function collect(
        address collector,
        uint256 curationId,
        address tokenContract,
        uint256 tokenId,
        uint256[] memory curationIds,
        address[] memory allocationIds,
        bytes memory collectMetaData
    ) external returns (address, uint256);
	
}