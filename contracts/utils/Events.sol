// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from './DataTypes.sol';

library Events {
    /**
     * @notice Emitted when the NFT contract's name and symbol are set at initialization.
     *
     * @param name The NFT name set.
     * @param symbol The NFT symbol set.
     * @param timestamp The current block timestamp.
     */
    event BaseInitialized(string name, string symbol, uint256 timestamp);

     /**
     * @notice Emitted when the hub state is set.
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
     * @notice Emitted when the governance address is changed. We emit the caller even though it should be the previous
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
     * @notice Emitted when a dispatcher is set for a specific profile.
     *
     * @param curationId The token ID of the curation for which the dispatcher is set.
     * @param dispatcher The dispatcher set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event DispatcherSet(
        uint256 indexed curationId, 
        address indexed dispatcher, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when `theBards` set `operator` access.
     */
    event OperatorSet(
        address indexed theBards, 
        address indexed operator, 
        bool allowed, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when `curationId` set `allocationId` access.
     */
    event AllocationIdSet(
        uint256 curationId,
        address allocationId,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
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
     * @param curationFundsRecipients The curation Ids where funds are sent after the trade.
     * @param timestamp The current block timestamp.
     */
    event CurationFundsRecipientsUpdated(
        uint256 indexed tokenId, 
        uint256[] curationFundsRecipients, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellerFundsBpses The fee that is sent to the sellers.
     * @param timestamp The current block timestamp.
     */
    event CurationSellerFundsBpsesUpdated(
        uint256 indexed tokenId, 
        uint32[] sellerFundsBpses, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param curationFundsBpses The fee that is sent to the curations.
     * @param timestamp The current block timestamp.
     */
    event CurationFundsBpsesUpdated(
        uint256 indexed tokenId, 
        uint32[] curationFundsBpses, 
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
     * @param stakingAddress The address of staking.
     * @param royaltyEngine The address of royaltyEngine.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleBaseInitialized(
        address indexed stakingAddress,
        address indexed royaltyEngine,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a mint module is added to or removed from the whitelist.
     *
     * @param mintModule The address of the mint module.
     * @param whitelisted Whether or not the follow module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event MintModuleWhitelisted(
        address indexed mintModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a market module is added to or removed from the whitelist.
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
     * @notice Emitted when a a default profile is set for a wallet as its main identity
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
     * @notice Emitted when a profile is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param to The address receiving the profile with the given profile ID.
     * @param handle The handle set for the profile.
     * @param contentURI The content uri set for the profile.
     * @param marketModule The profile's newly set market module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the market module's initialization. This is abi encoded
     * and totally depends on the market module chosen.
     * @param minterMarketModule The profile's newly set mint module. This CAN be the zero address.
     * @param minterMarketModuleReturnData The data returned from the mint module's initialization. This is abi encoded
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
        address minterMarketModule,
        bytes minterMarketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param curationId The newly created curation's token ID.
     * @param contentURI The content uri set for the profile.
     * @param marketModule The profile's newly set market module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the market module's initialization. This is abi encoded
     * and totally depends on the market module chosen.
     * @param minterMarketModule The profile's newly set mint module. This CAN be the zero address.
     * @param minterMarketModuleReturnData The data returned from the mint module's initialization. This is abi encoded
     * and totally depends on the mint module chosen.
     * @param timestamp The current block timestamp.
     */
    event CurationCreated(
        uint256 indexed profileId,
        uint256 indexed curationId,
        string contentURI,
        address marketModule,
        bytes marketModuleReturnData,
        address minterMarketModule,
        bytes minterMarketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation's market module is set.
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
     * @notice Emitted when a curation's minter market module is set.
     *
     * @param curationId The profile's token ID.
     * @param minterMarketModule The profile's newly set follow module. This CAN be the zero address.
     * @param minterMarketModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event MinterMarketModuleSet(
        uint256 indexed curationId,
        address minterMarketModule,
        bytes minterMarketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a profile creator is added to or removed from the whitelist.
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
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event CurationFeePayout(
        address indexed tokenContract, 
        uint256 indexed tokenId,
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
     * @notice Emitted when defaultReserveRatio is setted.
     * 
     * @param prevDefaultReserveRatio The previous defaultReserveRatio.
     * @param newDefaultReserveRatio The new defaultReserveRatio.
     * @param timestamp The current block timestamp.
     */
    event DefaultReserveRatioSet(
        uint32 indexed prevDefaultReserveRatio,
        uint32 indexed newDefaultReserveRatio,
        uint256 timestamp
    );

    /**
     * @notice Emitted when newMinimumStaking is setted.
     * 
     * @param prevMinimumStaking The previous newMinimumStaking.
     * @param newMinimumStaking The new newMinimumStaking.
     * @param timestamp The current block timestamp.
     */
    event MinimumStakingSet(
        uint256 indexed prevMinimumStaking,
        uint256 indexed newMinimumStaking,
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
     * @notice Emitted when a curation's URI is set.
     *
     * @param curationId The token ID of the curation for which the URI is set.
     * @param contentURI The URI set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event CurationContentURISet(
        uint256 indexed curationId, 
        string contentURI, 
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

    /**
     * @notice Emitted when rewards are assigned to a curation.
     */
    event RewardsAssigned(
        uint256 indexed curationId,
        address indexed allocationID,
        uint256 epoch,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when rewards are denied to a curation.
     */
    event RewardsDenied(
        uint256 indexed curationId, 
        address indexed allocationID, 
        uint256 epoch,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation is denied for claiming rewards.
     */
    event RewardsDenylistUpdated(
        uint256 indexed curationId, 
        uint256 sinceBlock,
        uint256 timestamp
    );

    /**
     * @notice Emitted when IssuanceRate update
     * 
     * @param prevIssuanceRate The preivous issuance rate of BCT token.
     * @param newIssuanceRate The new issuance rate of BCT token.
     * @param timestamp The current block timestamp.
     */
    event IssuanceRateSet(
        uint256 prevIssuanceRate,
        uint256 newIssuanceRate,
        uint256 timestamp
    );

    /**
     * @notice Emitted when TargetBondingRate update
     * 
     * @param prevTargetBondingRate The preivous target bonding rate of BCT token.
     * @param newTargetBondingRate The new target bonding rate of BCT token.
     * @param timestamp The current block timestamp.
     */
    event TargetBondingRateSet(
        uint256 prevTargetBondingRate,
        uint256 newTargetBondingRate,
        uint256 timestamp
    );

    /**
     * @notice Emitted when InflationChange update
     * 
     * @param prevInflationChange The preivous inflation Change of BCT token.
     * @param newInflationChange The new inflation Change of BCT token.
     * @param timestamp The current block timestamp.
     */
    event InflationChangeSet(
        uint256 prevInflationChange,
        uint256 newInflationChange,
        uint256 timestamp
    );

    /**
     * @notice Emitted when MinimumStakeingToken update
     * 
     * @param prevMinimumStakeingToken The previous Minimum amount of tokens on a curation required to accrue rewards.
     * @param newMinimumStakeingToken The New minimum amount of tokens on a curation required to accrue rewards.
     * @param timestamp The current block timestamp.
     */
    event MinimumStakeingTokenSet(
        uint256 prevMinimumStakeingToken,
        uint256 newMinimumStakeingToken,
        uint256 timestamp
    );

    /**
     * @notice Emitted when ThawingPeriod update
     * 
     * @param prevThawingPeriod The previous Period in blocks to wait for token withdrawals after unstaking
     * @param newThawingPeriod The new Period in blocks to wait for token withdrawals after unstaking
     * @param timestamp The current block timestamp.
     */
    event ThawingPeriodSet(
        uint32 prevThawingPeriod,
        uint32 newThawingPeriod,
        uint256 timestamp
    );

    /**
     * @notice Emitted when ThawingPeriod update
     * 
     * @param prevChannelDisputeEpochs The previous Period in blocks to wait for token withdrawals after unstaking
     * @param newChannelDisputeEpochs The new Period in blocks to wait for token withdrawals after unstaking
     * @param timestamp The current block timestamp.
     */
    event ChannelDisputeEpochsSet(
        uint32 prevChannelDisputeEpochs,
        uint32 newChannelDisputeEpochs,
        uint256 timestamp
    );

    /**
     * @notice Emitted when stakingAddress update
     * 
     * @param prevStakingAddress The previous stakingAddress
     * @param newStakingAddress The new stakingAddress
     * @param timestamp The current block timestamp.
     */
    event StakingAddressSet(
        address prevStakingAddress,
        address newStakingAddress,
        uint256 timestamp
    );

    /**
     * @notice Emitted when ReserveRatio update
     * 
     * @param prevStakingReserveRatio The previous prevStakingReserveRatio.
     * @param newStakingReserveRatio The new newStakingReserveRatio.
     * @param timestamp The current block timestamp.
     */
    event DefaultStakingReserveRatioSet(
        uint32 prevStakingReserveRatio,
        uint32 newStakingReserveRatio,
        uint256 timestamp
    );

    /**
     * @notice Emitted when RebateRatio update
     * 
     * @param alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param alphaDenominator Denominator of `alpha` in the cobb-douglas function
     * @param timestamp The current block timestamp.
     */
    event RebateRatioSet(
        uint32 alphaNumerator,
        uint32 alphaDenominator,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `delegator` deposited `tokens` on `curationId` as share.
     * The `delegator` receives `share` amount according to the pool bonding curve.
     * An amount of `stakingTax` will be collected and burned.
     */
    event CurationPoolStaked(
        address indexed delegator,
        uint256 indexed curationId,
        uint256 tokens,
        uint256 shares,
        uint256 stakingTax,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `delegator` undelegated `tokens` from `curationId`.
     * Tokens get locked for withdrawal after a period of time.
     * 
     * @param curationId Curation Id
     * @param delegator delegator
     * @param shares shares to be burnt
     * @param until A time tokens unlock for withdrawal.
     * @param timestamp The current block timestamp.
     */
    event StakeDelegatedLocked(
        uint256 indexed curationId,
        address indexed delegator,
        uint256 shares,
        uint256 until,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `delegator` withdrew delegated `tokens` from `curationId`.
     * 
     * @param curationId Curation Id
     * @param delegator delegator
     * @param tokens Amount of tokens withdrawn.
     * @param timestamp The current block timestamp.
     */
    event StakeDelegatedWithdrawn(
        uint256 indexed curationId,
        address indexed delegator,
        uint256 tokens,
        uint256 timestamp
    );

    /**
     * @notice Emitted when hub allocated `tokens` amount to `curationId`
     * during `epoch`.
     * `allocationID` indexer derived address used to identify the allocation.
     * `metadata` additional information related to the allocation.
     */
    event AllocationCreated(
        uint256 indexed curationId,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        bytes32 metadata,
        uint256 timestamp
    );

    /**
     * @notice Emitted when hub close an allocation in `epoch` for `curationId`.
     * An amount of `tokens` get unallocated from `curationId`.
     * The `effectiveAllocation` are the tokens allocated from creation to closing.
     */
    event AllocationClosed(
        uint256 indexed curationId,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        uint256 effectiveAllocationStake,
        address sender,
        uint256 stakeToCuration,
        bool isCurator,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `indexer` claimed a rebate on `subgraphDeploymentID` during `epoch`
     * related to the `forEpoch` rebate pool.
     * The rebate is for `tokens` amount and `unclaimedAllocationsCount` are left for claim
     * in the rebate pool. `delegationFees` collected and sent to delegation pool.
     */
    event RebateClaimed(
        uint256 indexed curationId,
        address indexed allocationID,
        address currency,
        uint256 epoch,
        uint256 forEpoch,
        uint256 tokens,
        uint256 unclaimedAllocationsCount,
        uint256 delegationFees,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `indexer` collected `tokens` amount in `epoch` for `allocationID`.
     * These funds are related to `subgraphDeploymentID`.
     * The `from` value is the sender of the collected funds.
     */
    event AllocationCollected(
        uint256 indexed curationId,
        uint256 epoch,
        uint256 tokens,
        address indexed allocationID,
        address from,
        address currency,
        uint256 timestamp
    );

    /**
     * @notice Emitted upon a successful collect action.
     *
     * @param collector The address collecting the NFT.
     * @param curationId The token ID of the curation.
     * @param tokenContractPointed The address of the NFT contract whose NFT is being collected.
     * @param tokenIdPointed The token ID of NFT being collected.
     * @param collectModuleData The data passed to the collect module.
     * @param timestamp The current block timestamp.
     */
    event Collected(
        address indexed collector,
        uint256 indexed curationId,
        address tokenContractPointed,
        uint256 tokenIdPointed,
        bytes collectModuleData,
        uint256 timestamp
    );
}