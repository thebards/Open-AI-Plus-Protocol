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
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param curationBps The bps of curation.
     */
    event CurationBpsUpdated(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        uint16 curationBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param sellers The addressers of the sellers.
     */
    event CurationSellersUpdated(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address[] sellers, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param sellerFundsRecipients The addresses where funds are sent after the trade.
     */
    event CurationSellerFundsRecipientsUpdated(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address[] sellerFundsRecipients, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param sellerBpses The fee that is sent to the sellers.
     */
    event CurationSellerBpsesUpdated(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        uint16[] sellerBpses, 
        uint256 timestamp
    );
   
    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param stakingBps The bps of staking.
     */
    event StakingBpsUpdated(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        uint16 stakingBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when an curation is created.
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of a NFT.
     * @param curationData The curation data.
     */
    event CurationCreated(
        address indexed tokenContract, 
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
}