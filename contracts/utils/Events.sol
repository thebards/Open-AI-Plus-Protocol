// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
     * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the governance address.
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the emergency admin address.
     * @param oldEmergencyAdmin The previous emergency admin address.
     * @param newEmergencyAdmin The new emergency admin address set.
     * @param timestamp The current block timestamp.
     */
    event EmergencyAdminSet(
        address indexed caller,
        address indexed oldEmergencyAdmin,
        address indexed newEmergencyAdmin,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param curationBps The bps of curation.
     * @param timestamp The current block timestamp.
     */
    event CurationBpsUpdated(
        uint256 indexed tokenId, 
        uint32 curationBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellers The addressers of the sellers.
     * @param timestamp The current block timestamp.
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
     * @param timestamp The current block timestamp.
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
     * @param timestamp The current block timestamp.
     */
    event CurationSellerBpsesUpdated(
        uint256 indexed tokenId, 
        uint32[] sellerBpses, 
        uint256 timestamp
    );
   
    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param stakingBps The bps of staking.
     * @param timestamp The current block timestamp.
     */
    event StakingBpsUpdated(
        uint256 indexed tokenId, 
        uint32 stakingBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when an curation is created.
     * @param tokenId The token Id of a NFT.
     * @param curationData The curation data.
     * @param timestamp The current block timestamp.
     */
    event CurationInitialized(
        uint256 indexed tokenId,
        bytes curationData,
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
        uint32 indexed prevProtocolFee,
        uint32 indexed newProtocolFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol default curation fee is set.
     *
     * @param prevDefaultCurationBps The previous default curation fee in BPS.
     * @param newDefaultCurationBps The new default curation fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event DefaultCurationFeeSet(
        uint32 indexed prevDefaultCurationBps,
        uint32 indexed newDefaultCurationBps,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol default staking fee is set.
     *
     * @param prevDefaultStakingBps The previous default staking fee in BPS.
     * @param newDefaultStakingBps The new default staking fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event DefaultStakingFeeSet(
        uint32 indexed prevDefaultStakingBps,
        uint32 indexed newDefaultStakingBps,
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
     * @param minter The minter contract address used.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleBaseConstructed(
        address indexed bardsDaoData, 
        address indexed minter,
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
     * @dev Emitted when a a default profile is set for a wallet as its main identity
     *
     * @param wallet The wallet which set or unset its default profile.
     * @param profileId The token ID of the profile being set as default, or zero.
     * @param timestamp The current block timestamp.
     */
    event DefaultProfileSet(
        address indexed wallet, 
        uint256 indexed profileId, 
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

    /**
     * @dev Emitted when a profile creator is added to or removed from the whitelist.
     *
     * @param profileCreator The address of the profile creator.
     * @param whitelisted Whether or not the profile creator is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreatorWhitelisted(
        address indexed profileCreator,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when royalties are paid
     * 
     * @param tokenContract The ERC-721 token address of the royalty payout
     * @param tokenId The ERC-721 token ID of the royalty payout
     * @param recipient The recipient address of the royalty
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event RoyaltyPayout(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address recipient, 
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when sell fee are paid
     * 
     * @param tokenContract The ERC-721 token address of the sell fee payout
     * @param tokenId The ERC-721 token ID of the sell fee payout
     * @param recipient The recipient address of the sell fee
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event SellFeePayout(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address recipient, 
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when curation fees are paid
     * 
     * @param tokenContract The ERC-721 token address of the curation fee payout
     * @param tokenId The ERC-721 token ID of the curation fee payout
     * @param recipient The recipient address of the curation fee
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event CurationFeePayout(
        address indexed tokenContract, 
        uint256 indexed tokenId,
        address recipient,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when minters are added. 
     * 
     * @param account A minter address
     * @param timestamp The current block timestamp.
     */
    event MinterAdded(
        address indexed account, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when minters are removed.
     * 
     * @param account A minter address
     * @param timestamp The current block timestamp.
     */
    event MinterRemoved(
        address indexed account,
        uint256 timestamp
    );

    /**
     * @notice Emitted when defaultStakingReserveRatio is setted.
     * 
     * @param prevDefaultReserveRatio The previous defaultStakingReserveRatio.
     * @param newDefaultReserveRatio The new defaultStakingReserveRatio.
     * @param timestamp The current block timestamp.
     */
    event DefaultStakingReserveRatioSet(
        uint32 indexed prevDefaultReserveRatio,
        uint32 indexed newDefaultReserveRatio,
        uint256 timestamp
    );

    /**
     * @notice Emitted when newMinimumCurationStaking is setted.
     * 
     * @param prevMinimumCurationStaking The previous newMinimumCurationStaking.
     * @param newMinimumCurationStaking The new newMinimumCurationStaking.
     * @param timestamp The current block timestamp.
     */
    event MinimumCurationStakingSet(
        uint256 indexed prevMinimumCurationStaking,
        uint256 indexed newMinimumCurationStaking,
        uint256 timestamp
    );

    /**
     * @notice Emitted when stakingTaxPercentage is setted.
     * 
     * @param prevStakingTaxPercentage The previous stakingTaxPercentage.
     * @param newStakingTaxPercentage The new stakingTaxPercentage.
     * @param timestamp The current block timestamp.
     */
    event StakingTaxPercentageSet(
        uint32 indexed prevStakingTaxPercentage,
        uint32 indexed newStakingTaxPercentage,
        uint256 timestamp
    );

    /**
     * @notice Emitted when bardsShareTokenImpl is setted.
     * 
     * @param prevBardsShareTokenImpl The previous bardsShareTokenImpl.
     * @param newBardsShareTokenImpl The new bardsShareTokenImpl.
     * @param timestamp The current block timestamp.
     */
    event BardsShareTokenImplSet(
        address indexed prevBardsShareTokenImpl,
        address indexed newBardsShareTokenImpl,
        uint256 timestamp
    );

    /**
     * @notice Emitted when bardsCurationTokenImpl is setted.
     * 
     * @param prevBardsCurationTokenImpl The previous bardsCurationTokenImpl.
     * @param newBardsCurationTokenImpl The new bardsCurationTokenImpl.
     * @param timestamp The current block timestamp.
     */
    event BardsCurationTokenImplSet(
        address indexed prevBardsCurationTokenImpl,
        address indexed newBardsCurationTokenImpl,
        uint256 timestamp
    );

    /**
     * @notice Emitted when staking pool earn fees.
     * 
     * @param curationId Curation ID.
     * @param amount The amount of fees earned.
     * @param timestamp The current block timestamp.
     */
    event StakingPoolEarned(
        uint256 indexed curationId,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when delegator deposited token on curationId as staking signal.
     * 
     * @param delegator Delegator who staking.
     * @param curationId The curation Id deposited
     * @param amount The amount of token deposited.
     * @param signal receives `signal` amount according to the curation pool bonding curve
     * @param stakingTax An amount of `curationTax` will be collected and burned.
     * @param timestamp The current block timestamp.
     */
    event Signalled(
        address indexed delegator,
        uint256 indexed curationId,
        uint256 amount,
        uint256 signal,
        uint256 stakingTax,
        uint256 timestamp
    );

    /**
     * @notice Emitted when delegator burn signal.
     * 
     * @param delegator Delegator who staking.
     * @param curationId The curation Id deposited
     * @param amount The amount of token deposited.
     * @param signal receives `signal` amount according to the curation pool bonding curve
     * @param timestamp The current block timestamp.
     */
    event Burned(
        address indexed delegator,
        uint256 indexed curationId,
        uint256 amount,
        uint256 signal,
        uint256 timestamp
    );

    /**
     * @notice Emitted when contract address update
     * 
     * @param id contract id
     * @param contractAddress contract Address
     * @param timestamp The current block timestamp.
     */
    event ContractRegistered(
        bytes32 indexed id, 
        address contractAddress,
        uint256 timestamp
    );

    /**
     * @notice Emitted when contract with `nameHash` is synced to `contractAddress`.
     * 
     * @param nameHash name Hash
     * @param contractAddress contract Address
     * @param timestamp The current block timestamp.
     */
    event ContractSynced(
        bytes32 indexed nameHash, 
        address contractAddress,
        uint256 timestamp
    );

    /**
     * @notice Emitted when hub setted
     * 
     * @param hub the hub address.
     * @param timestamp The current block timestamp.
     */
    event HUBSet(
        address indexed hub,
        uint256 timestamp
    );

    /**
     * @notice Emitted when epoch run
     * 
     * @param epoch epoch 
     * @param caller epoch
     * @param timestamp The current block timestamp.
     */
    event EpochRun(
        uint256 indexed epoch, 
        address caller,
        uint256 timestamp
    );

    /**
     * @notice Emitted when epoch length updated
     * 
     * @param epoch epoch
     * @param epochLength epoch length
     * @param timestamp The current block timestamp.
     */
    event EpochLengthUpdate(
        uint256 indexed epoch, 
        uint256 epochLength,
        uint256 timestamp
    );

}