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

	/**
     * @notice Creates a curation with the specified parameters. 
     */
	function initializeCuration(DataTypes.InitializeCurationData memory _vars) external;

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

				/* SETTERs */

    /**
     * @notice Sets the sellerFundsRecipients of the sellers for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param sellerFundsRecipients The bpses of seller funds
     */
    function setSellerFundsRecipientsParams(uint256 tokenId, address[] calldata sellerFundsRecipients) external;

    /**
     * @notice Sets the curationFundsRecipients of the sellers for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationFundsRecipients The bpses of curation funds
     */
    function setCurationFundsRecipientsParams(uint256 tokenId, uint256[] calldata curationFundsRecipients) external;


    /**
     * @notice Sets the fee that is sent to the sellers for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param sellerFundsBpses The fee that is sent to the sellers.
     */
    function setSellerFundsBpsesParams(uint256 tokenId, uint32[] calldata sellerFundsBpses) external;

    /**
     * @notice Sets the fee that is sent to the curation for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationFundsBpses The fee that is sent to the curations.
     */
    function setCurationFundsBpsesParams(uint256 tokenId, uint32[] calldata curationFundsBpses) external;

	/**
     * @notice Sets fee parameters for a NFT
	 *
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationBps The bps of curation
     * @param stakingBps The bps of staking
     */
    function setBpsParams(uint256 tokenId, uint32 curationBps, uint32 stakingBps) external;

    /**
     * @notice Sets curation fee parameters for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationBps The bps of curation
     */
    function setCurationBpsParams(uint256 tokenId, uint32 curationBps) external;

    /**
     * @notice Sets staking fee parameters for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param stakingBps The bps of staking
     */
    function setStakingBpsParams(uint256 tokenId, uint32 stakingBps) external;
}