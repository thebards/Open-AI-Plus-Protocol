// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
/**
 * @title IERC721MultFee
 * @author TheBards Protocol
 *
 * @notice This is an expansion of the IERC721 interface that includes a struct for token data,
 * which contains the token owner, curation BPS, staking BPS and the mint timestamp as well as associated getters.
 */
interface IERC721MultFee is IERC721 {

    /**
     * @notice Contains the owner address, curation BPS, staking BPS and the mint timestamp for every NFT.
     *
     * Note: Instead of the owner address in the _tokenOwners private mapping, we now store it in the
     * _tokenData mapping, alongside the unchanging mintTimestamp.
     *
     * @param owner The token owner.
	 * @param curationBps The points fee of willing to share of the NFT income to curators.
	 * @param stakingBps The points fee of willing to share of the NFT income to delegators who staking tokens.
     * @param mintTimestamp The mint timestamp.
     */
    struct TokenData {
        address owner;
		uint16 curationBps;
		uint16 stakingBps;
        uint96 mintTimestamp;
    }

	/**
     * @notice Returns the curation BPS associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint16 curation BPS
     */
    function curationBpsOf(uint256 tokenId) external view returns (uint16);

	/**
     * @notice Returns the staking BPS associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query thestaking BPS for.
     *
     * @return uint16 staking BPS
     */
    function stakingBpsOf(uint256 tokenId) external view returns (uint16);

    /**
     * @notice Returns the mint timestamp associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the mint timestamp for.
     *
     * @return uint256 mint timestamp, this is stored as a uint96 but returned as a uint256 to reduce unnecessary
     * padding.
     */
    function mintTimestampOf(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the token data associated with a given NFT. This allows fetching the token owner and
     * mint timestamp in a single call.
     *
     * @param tokenId The token ID of the NFT to query the token data for.
     *
     * @return TokenData token data struct containing the owner address, curation BPS, staking BPS and the mint timestamp.
     */
    function tokenDataOf(uint256 tokenId) external view returns (TokenData memory);

    /**
     * @notice Returns whether a token with the given token ID exists.
     *
     * @param tokenId The token ID of the NFT to check existence for.
     *
     * @return bool True if the token exists.
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @notice Sets fee parameters for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationBps The bps of curation
     * @param stakingBps The bps of staking
     */
    function setBpsParams(uint256 tokenId, uint16 curationBps, uint16 stakingBps) external;

    /**
     * @notice Sets curation fee parameters for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param curationBps The bps of curation
     */
    function setCurationBpsParams(uint256 tokenId, uint16 curationBps) external;

    /**
     * @notice Sets staking fee parameters for a NFT
     * 
     * @param tokenId The token Id of the NFT to set fee params.
     * @param stakingBps The bps of staking
     */
    function setStakingBpsParams(uint256 tokenId, uint16 stakingBps) external;

    /**
     * @notice Computes the curation fee for a given uint256 amount
     * @param tokenId The token Id of a NFT to compute the fee for.
     * @param amount The amount to compute the fee for.
     * @return feeAmount The amount to be paid out to the fee recipient.
     */
    function getCurationFeeAmount(uint256 tokenId, uint256 amount) external view returns (uint256 feeAmount);

    /**
     * @notice Computes the staking fee for a given uint256 amount
     * @param tokenId The token Id of a NFT to compute the fee for.
     * @param amount The amount to compute the fee for.
     * @return feeAmount The amount to be paid out to the fee recipient.
     */
    function getStakingFeeAmount(uint256 tokenId, uint256 amount) external view returns (uint256 feeAmount);
}