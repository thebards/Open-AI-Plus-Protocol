// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

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
     * @notice Returns the sellers associated with a given NFT, stored only once upon initial mint.
     *
	 * @param tokenContract The address of token contract.
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return address[] The addresses of the sellers
     */
    function sellersOf(address tokenContract, uint256 tokenId) external view returns (address[] memory);
	

	/**
     * @notice Returns the sellerFundsRecipients associated with a given NFT, stored only once upon initial mint.
     *
	 * @param tokenContract The address of token contract.
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return address[] The addresses of the sellers
     */
    function sellerFundsRecipientsOf(address tokenContract, uint256 tokenId) external view returns (address[] memory);

	/**
     * @notice Returns the sellerBpses associated with a given NFT, stored only once upon initial mint.
     *
	 * @param tokenContract The address of token contract.
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint16[] The fee that is sent to the sellers.
     */
    function sellerBpsesOf(address tokenContract, uint256 tokenId) external view returns (uint16[] memory);

	/**
     * @notice Returns the curation BPS associated with a given NFT, stored only once upon initial mint.
     *
	 * @param tokenContract The address of token contract.
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint16 curation BPS
     */
    function curationBpsOf(address tokenContract, uint256 tokenId) external view returns (uint16);

	/**
     * @notice Returns the staking BPS associated with a given NFT, stored only once upon initial mint.
     *
	 * @param tokenContract The address of token contract.
     * @param tokenId The token ID of the NFT to query thestaking BPS for.
     *
     * @return uint16 staking BPS
     */
    function stakingBpsOf(address tokenContract, uint256 tokenId) external view returns (uint16);

	/**
     * @notice Returns the curation data associated with a given NFT. This allows fetching the curation BPS and 
	 * staking BPS in a single call.
	 * @param tokenContract The address of token contract.
     * @param tokenId The token ID of the NFT to query the token data for.
     *
     * @return CurationData curation data struct containing the curation BPS and staking BPS.
     */
    function curationDataOf(address tokenContract, uint256 tokenId) external view returns (DataTypes.CurationData memory);

    /**
     * @notice Computes the curation fee for a given uint256 amount
	 *
	 * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT to compute the fee for.
     * @param amount The amount to compute the fee for.
     * @return feeAmount The amount to be paid out to the fee recipient.
     */
    function getCurationFeeAmount(address tokenContract, uint256 tokenId, uint256 amount) external view returns (uint256 feeAmount);

    /**
     * @notice Computes the staking fee for a given uint256 amount
	 *
	 * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT to compute the fee for.
     * @param amount The amount to compute the fee for.
     * @return feeAmount The amount to be paid out to the fee recipient.
     */
    function getStakingFeeAmount(address tokenContract, uint256 tokenId, uint256 amount) external view returns (uint256 feeAmount);

				/* SETTERs */

    /**
     * @notice Sets the addresses of the sellers for a NFT.
     * 
	 * @param tokenContract The address of token contract.
     * @param tokenId The token Id of the NFT to set fee params.
     * @param sellers The addresses of the sellers.
     */
    function setSellersParams(address tokenContract, uint256 tokenId, address[] calldata sellers) external;

    /**
     * @notice Sets the sellerFundsRecipients of the sellers for a NFT
     * 
	 * @param tokenContract The address of token contract.
     * @param tokenId The token Id of the NFT to set fee params.
     * @param sellerFundsRecipients The bps of curation
     */
    function setSellerFundsRecipientsParams(address tokenContract, uint256 tokenId, address[] calldata sellerFundsRecipients) external;

    /**
     * @notice Sets the fee that is sent to the sellers for a NFT
     * 
	 * @param tokenContract The address of token contract.
     * @param tokenId The token Id of the NFT to set fee params.
     * @param sellerBpses The fee that is sent to the sellers.
     */
    function setSellerBpsesParams(address tokenContract, uint256 tokenId, uint16[] calldata sellerBpses) external;

	/**
     * @notice Sets fee parameters for a NFT
	 *
	 * @param tokenContract The address of token contract.
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationBps The bps of curation
     * @param stakingBps The bps of staking
     */
    function setBpsParams(address tokenContract, uint256 tokenId, uint16 curationBps, uint16 stakingBps) external;

    /**
     * @notice Sets curation fee parameters for a NFT
     * 
	 * @param tokenContract The address of token contract.
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationBps The bps of curation
     */
    function setCurationBpsParams(address tokenContract, uint256 tokenId, uint16 curationBps) external;

    /**
     * @notice Sets staking fee parameters for a NFT
     * 
	 * @param tokenContract The address of token contract.
     * @param tokenId The token Id of the NFT to set fee params.
     * @param stakingBps The bps of staking
     */
    function setStakingBpsParams(address tokenContract, uint256 tokenId, uint16 stakingBps) external;
}