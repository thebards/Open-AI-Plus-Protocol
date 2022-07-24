// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title DataTypes
 * @author TheBards Protocol
 *
 * @notice A standard library of data types used throughout the bards Protocol.
 */
library DataTypes {

	enum ContentType {
		aaa
	}

	enum CurationType {
		aaa
	}

	/**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
     */
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     * @notice Contains the curation BPS and staking BPSfor every Curation.
     *
	 * @param sellers The addresses of the sellers.
	 * @param sellerFundsRecipients The addresses where funds are sent after the trade.
	 * @param sellerBpses The fee that is sent to the sellers.
	 * @param curationBps The points fee of willing to share of the NFT income to curators.
	 * @param stakingBps The points fee of willing to share of the NFT income to delegators who staking tokens.
     */
    struct CurationData {
		address[] sellers;
        address[] sellerFundsRecipients;
		uint16[] sellerBpses;
		uint16 curationBps;
		uint16 stakingBps;
    }

    /**
     * @notice A struct containing the parameters required for the `createCuration()` function.
     *
     * @param tokenContract The address of token contract.
     * @param tokenId The token id.
     * @param curationData The data of curation.
     */
    struct CreateCurationData {
        address tokenContract;
        uint256 tokenId;
        CurationData curationData;
    }

    /**
     * @notice The metadata for a fix price market.
     *
     * @param currency The currency to ask.
     * @param price The fix price of nft.
     */
    struct FixPriceMarketData {
        address currency;
        uint256 price;
    }

    /**
     * @notice The metadata of a protocol fee setting
     * @param feeBps The basis points fee
     * @param treasury The recipient of the fee
     */
    struct ProtocolFeeSetting {
        uint16 feeBps;
        address treasury;
    }
}