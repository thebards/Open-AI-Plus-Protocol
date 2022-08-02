// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {DataTypes} from './DataTypes.sol';

library Events {
    /**
     * @dev Emitted when the NFT contract's name and symbol are set at initialization.
     *
     * @param name The NFT name set.
     * @param symbol The NFT symbol set.
     * @param timestamp The current block timestamp.
     */
    event BaseInitialized(string name, string symbol, uint256 timestamp);

     /**
     * @dev Emitted when the hub state is set.
     *
     * @param caller The caller who set the state.
     * @param prevState The previous protocol state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param newState The newly set state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param timestamp The current block timestamp.
     */
    event StateSet(
        address indexed caller,
        DataTypes.ProtocolState indexed prevState,
        DataTypes.ProtocolState indexed newState,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param curationBps The bps of curation.
     */
    event CurationBpsUpdated(
        uint256 indexed tokenId, 
        uint16 curationBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellers The addressers of the sellers.
     */
    event CurationSellersUpdated(
        uint256 indexed tokenId, 
        address[] sellers, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellerFundsRecipients The addresses where funds are sent after the trade.
     */
    event CurationSellerFundsRecipientsUpdated(
        uint256 indexed tokenId, 
        address[] sellerFundsRecipients, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellerBpses The fee that is sent to the sellers.
     */
    event CurationSellerBpsesUpdated(
        uint256 indexed tokenId, 
        uint16[] sellerBpses, 
        uint256 timestamp
    );
   
    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param stakingBps The bps of staking.
     */
    event StakingBpsUpdated(
        uint256 indexed tokenId, 
        uint16 stakingBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when an curation is created.
     * @param tokenId The token Id of a NFT.
     * @param curationData The curation data.
     */
    event CurationCreated(
        uint256 indexed tokenId, 
        DataTypes.CurationData curationData, 
        uint256 timestamp
    );

     /**
     * @notice Emitted when the Bards protocol treasury address is set.
     *
     * @param prevTreasury The previous treasury address.
     * @param newTreasury The new treasury address set.
     * @param timestamp The current block timestamp.
     */
    event ProtocolTreasurySet(
        address indexed prevTreasury,
        address indexed newTreasury,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol fee is set.
     *
     * @param prevProtocolFee The previous treasury fee in BPS.
     * @param newProtocolFee The new treasury fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event ProtocolFeeSet(
        uint16 indexed prevProtocolFee,
        uint16 indexed newProtocolFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a currency is added to or removed from the Protocol fee whitelist.
     *
     * @param currency The currency address.
     * @param prevWhitelisted Whether or not the currency was previously whitelisted.
     * @param whitelisted Whether or not the currency is whitelisted.
     * @param timestamp The current block timestamp.
     */
    event ProtocolCurrencyWhitelisted(
        address indexed currency,
        bool indexed prevWhitelisted,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol governance address is set.
     *
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event ProtocolGovernanceSet(
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a market module inheriting from the `MarketModuleBase` is constructed.
     *
     * @param bardsDaoData The ModuleGlobals contract address used.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleBaseConstructed(
        address indexed bardsDaoData, 
        uint256 timestamp
    );

        /**
     * @dev Emitted when a market module is added to or removed from the whitelist.
     *
     * @param marketModule The address of the market module.
     * @param whitelisted Whether or not the follow module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleWhitelisted(
        address indexed marketModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a profile is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param to The address receiving the profile with the given profile ID.
     * @param handle The handle set for the profile.
     * @param contentURI The content uri set for the profile.
     * @param marketModule The profile's newly set market module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the market module's initialization. This is abi encoded
     * and totally depends on the market module chosen.
     * @param mintModule The profile's newly set mint module. This CAN be the zero address.
     * @param mintModuleReturnData The data returned from the mint module's initialization. This is abi encoded
     * and totally depends on the mint module chosen.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreated(
        uint256 indexed profileId,
        address indexed creator,
        address indexed to,
        string handle,
        string contentURI,
        address marketModule,
        bytes marketModuleReturnData,
        address mintModule,
        bytes mintModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a curation is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param curationId The newly created curation's token ID.
     * @param contentURI The content uri set for the profile.
     * @param marketModule The profile's newly set market module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the market module's initialization. This is abi encoded
     * and totally depends on the market module chosen.
     * @param mintModule The profile's newly set mint module. This CAN be the zero address.
     * @param mintModuleReturnData The data returned from the mint module's initialization. This is abi encoded
     * and totally depends on the mint module chosen.
     * @param timestamp The current block timestamp.
     */
    event CurationCreated(
        uint256 indexed profileId,
        uint256 indexed curationId,
        string contentURI,
        address marketModule,
        bytes marketModuleReturnData,
        address mintModule,
        bytes mintModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a curation's market module is set.
     *
     * @param curationId The profile's token ID.
     * @param marketModule The profile's newly set follow module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleSet(
        uint256 indexed curationId,
        address marketModule,
        bytes marketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a curation's mint module is set.
     *
     * @param curationId The profile's token ID.
     * @param mintModule The profile's newly set follow module. This CAN be the zero address.
     * @param mintModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event MintModuleSet(
        uint256 indexed curationId,
        address mintModule,
        bytes mintModuleReturnData,
        uint256 timestamp
    );
}