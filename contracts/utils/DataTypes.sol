// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title DataTypes
 * @author TheBards Protocol
 *
 * @notice A standard library of data types used throughout the bards Protocol.
 */
library DataTypes {

	enum ContentType {
		Microblog,
        Article,
        Audio,
        Video
	}

	enum CurationType {
		Profile,
        Content,
        Combined,
        Protfolio,
        Feed,
        Dapp
	}

    /**
     * @notice An enum containing the different states the protocol can be in, limiting certain actions.
     *
     * @param Unpaused The fully unpaused state.
     * @param CurationPaused The state where only curation creation functions are paused.
     * @param Paused The fully paused state.
     */
    enum ProtocolState {
        Unpaused,
        CurationPaused,
        Paused
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
     * @notice A struct containing the parameters required for the `setDefaultProfileWithSig()` function. Parameters are
     * the same as the regular `setDefaultProfile()` function, with an added EIP712Signature.
     *
     * @param wallet The address of the wallet setting the default profile.
     * @param profileId The token ID of the profile which will be set as default, or zero.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetDefaultProfileWithSigData {
        address wallet;
        uint256 profileId;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setMarketModule()` function.
     *
     * @param curationId The token ID of the curation to change the marketModule for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The marketModule to set for the given curation, must be whitelisted.
     * @param marketModuleInitData The data to be passed to the marketModule for initialization.
     */
    struct SetMarketModuleData {
        uint256 curationId;
        address tokenContract;
        uint256 tokenId;
        address marketModule;
        bytes marketModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `setMarketModuleWithSig()` function. Parameters are
     * the same as the regular `setMarketModule()` function, with an added EIP712Signature.
     *
     * @param curationId The token ID of the curation to change the marketModule for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The marketModule to set for the given curation, must be whitelisted.
     * @param marketModuleInitData The data to be passed to the marketModule for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetMarketModuleWithSigData {
        uint256 curationId;
        address tokenContract;
        uint256 tokenId;
        address marketModule;
        bytes marketModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice Contains the curation BPS and staking BPSfor every Curation.
     *
	 * @param sellers The addresses of the sellers.
	 * @param sellerFundsRecipients The addresses where funds are sent after the trade.
	 * @param sellerBpses The fee that is sent to the sellers.
	 * @param curationBps The points fee of willing to share of the NFT income to curators.
	 * @param stakingBps The points fee of willing to share of the NFT income to delegators who staking tokens.
     * @param treasury The recipient of the fee
     */
    struct CurationData {
		address[] sellers;
        address[] sellerFundsRecipients;
		uint32[] sellerBpses;
		uint32 curationBps;
		uint32 stakingBps;
        address treasury;
    }

    /**
     * @notice A struct containing the parameters required for the `createCuration()` function.
     *
     * @param tokenId The token id.
     * @param curationData The data of CurationData curation.
     */
    struct InitializeCurationData {
        uint256 tokenId;
        bytes curationData;
    }

    /**
     * @notice The metadata for a fix price market.
     * @param seller The seller of nft
     * @param currency The currency to ask.
     * @param price The fix price of nft.
     * @param treasury The recipient of the fee
     */
    struct FixPriceMarketData {
        address seller;
        address currency;
        uint256 price;
        address treasury;
    }

    /**
     * @notice The metadata of a protocol fee setting
     * @param feeBps The basis points fee
     * @param treasury The recipient of the fee
     * @param curationBps The default points fee of willing to share of the NFT income to curators.
	 * @param stakingBps The default points fee of willing to share of the NFT income to delegators who staking tokens.
     */
    struct ProtocolFeeSetting {
        uint32 feeBps;
        address treasury;
        uint32 defaultCurationBps;
		uint32 defaultStakingBps;
    }

    /**
     * @notice A struct containing data associated with each new Content Curation.
     *
     * @param handle The profile's associated handle.
       @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param contentURI The URI associated with this publication.
     * @param marketModule The address of the current market module in use by this curation to trade itself, can be empty.
     * @param mintModule The address of the current mint module in use by this curation, can be empty. 
     * Make sure each curation can mint its own NFTs. MintModule is marketModule, but the initialization parameters are different.
     */
    struct CurationStruct {
        string handle;
        address tokenContractPointed;
        uint256 tokenIdPointed;
        string contentURI;
        address marketModule;
        address mintModule;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` and `creationCuration` function.
     *
     * @param to The address receiving the curation.
     * @param profileId the profile id creating the curation.
     * @param curationId the curation ID.
     * @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param contentURI The URI to set for the profile metadata.
     * @param marketModule The market module to use, can be the zero address to trade itself.
     * @param marketModuleInitData The market module initialization data, if any.
     * @param mintModule The mint module to use, can be the zero address. Make sure each curation can mint its own NFTs.
     * MintModule is marketModule, but the initialization parameters are different.
     * @param mintModuleInitData The mint module initialization data, if any.
     * @param curationMetaData The data of CurationData struct.
     */
    struct CreateCurationData {
        address to;
        uint256 profileId;
        uint256 curationId;
        address tokenContractPointed;
        uint256 tokenIdPointed;
        string handle;
        string contentURI;
        address marketModule;
        bytes marketModuleInitData;
        address mintModule;
        bytes mintModuleInitData;
        bytes curationMetaData;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` and `creationCuration` function.
     *
     * @param to The address receiving the curation.
     * @param profileId the profile id creating the curation
     * @param curationId the curation ID.
     * @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param contentURI The URI to set for the profile metadata.
     * @param marketModule The market module to use, can be the zero address to trade itself.
     * @param marketModuleInitData The market module initialization data, if any.
     * @param mintModule The mint module to use, can be the zero address. Make sure each curation can mint its own NFTs.
     * MintModule is marketModule, but the initialization parameters are different.
     * @param mintModuleInitData The mint module initialization data, if any.
     * @param curationMetaData The data of CurationData struct.
     */
    struct CreateCurationWithSigData {
        address to;
        uint256 profileId;
        uint256 curationId;
        address tokenContractPointed;
        uint256 tokenIdPointed;
        string handle;
        string contentURI;
        address marketModule;
        bytes marketModuleInitData;
        address mintModule;
        bytes mintModuleInitData;
        bytes curationMetaData;
        EIP712Signature sig;
    }

    /**
     * @notice A Struct containing the parameters required for the staking module.
     * @param amount BCT Tokens stored as reserves for the curation.
     * @param reserveRatio Ratio for the bonding curve.
     * @param bct Curation token contract for this curation staking pool.
     */
    struct StakingStruct {
        uint256 amount;
        uint32 reserveRatio;
        address bst;
    }
}