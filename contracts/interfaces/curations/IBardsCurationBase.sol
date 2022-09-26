// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsCurationBase
 * @author TheBards Protocol
 *
 * @notice This is the interface for the BardsCurationBase contract. 
 * The proportion of relevant benefit-sharing involved in the curation is specified.
 */
interface IBardsCurationBase {
				/* GETTERs */

	/**
     * @notice Returns the sellerFundsRecipients associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return address[] The addresses of the sellers
     */
    function sellerFundsRecipientsOf(uint256 tokenId) external view returns (address[] memory);

	/**
     * @notice Returns the curationFundsRecipients associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint256[] The addresses of the sellers
     */
    function curationFundsRecipientsOf(uint256 tokenId) external view returns (uint256[] memory);

	/**
     * @notice Returns the sellerFundsBpses associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint32[] The fee that is sent to the sellers.
     */
    function sellerFundsBpsesOf(uint256 tokenId) external view returns (uint32[] memory);

	/**
     * @notice Returns the curationFundsBpses associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint32[] The fee that is sent to the sellers.
     */
    function curationFundsBpsesOf(uint256 tokenId) external view returns (uint32[] memory);


	/**
     * @notice Returns the curation BPS associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint32 curation BPS
     */
    function curationBpsOf(uint256 tokenId) external view returns (uint32);

	/**
     * @notice Returns the staking BPS associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query thestaking BPS for.
     *
     * @return uint32 staking BPS
     */
    function stakingBpsOf(uint256 tokenId) external view returns (uint32);

	/**
     * @notice Returns the curation data associated with a given NFT. This allows fetching the curation BPS and 
	 * staking BPS in a single call.
     * @param tokenId The token ID of the NFT to query the token data for.
     *
     * @return CurationData curation data struct containing the curation BPS and staking BPS.
     */
    function curationDataOf(uint256 tokenId) external view returns (DataTypes.CurationData memory);

    /**
     * @notice Computes the curation fee for a given uint256 amount
	 *
     * @param tokenId The token Id of a NFT to compute the fee for.
     * @param amount The amount to compute the fee for.
     * @return feeAmount The amount to be paid out to the fee recipient.
     */
    function getCurationFeeAmount(uint256 tokenId, uint256 amount) external view returns (uint256 feeAmount);

    /**
     * @notice Computes the staking fee for a given uint256 amount
	 *
     * @param tokenId The token Id of a NFT to compute the fee for.
     * @param amount The amount to compute the fee for.
     * @return feeAmount The amount to be paid out to the fee recipient.
     */
    function getStakingFeeAmount(uint256 tokenId, uint256 amount) external view returns (uint256 feeAmount);
}