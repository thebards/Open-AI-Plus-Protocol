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
     * @notice Contains the owner address and the mint timestamp for every NFT.
     *
     * Note: Instead of the owner address in the _tokenOwners private mapping, we now store it in the
     * _tokenData mapping, alongside the unchanging mintTimestamp.
     *
     * @param owner The token owner.
     * @param mintTimestamp The mint timestamp.
     */
    struct TokenData {
        address owner;
        uint96 mintTimestamp;
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
     * @param minter The minter of NFT.
     */
    struct FixPriceMarketData {
        address seller;
        address currency;
        uint256 price;
        address treasury;
        address minter;
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
     * @param curationType The Type of curation.
     * @param handle The profile's associated handle.
       @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param contentURI The URI associated with this publication.
     * @param marketModule The address of the current market module in use by this curation to trade itself, can be empty.
     * @param mintModule The address of the current mint module in use by this curation, can be empty. 
     * Make sure each curation can mint its own NFTs. MintModule is marketModule, but the initialization parameters are different.
     */
    struct CurationStruct {
        CurationType curationType;
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
     * @param curationType The Type of curation.
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
        CurationType curationType;
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
     * @param curationType The Type of curation.
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
        CurationType curationType;
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
     * @notice Possible states an allocation can be
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     * - Finalized = Closed && closedAtEpoch + channelDisputeEpochs > now()
     * - Claimed = not Null && tokens == 0
     */
    enum AllocationState {
        Null,
        Active,
        Closed,
        Finalized,
        Claimed
    }

    /**
     * @notice A struct containing the parameters required for the multi-currency fees earned.
     * 
     * @param totalShare Total share during the fees pool's epoch
     * @param currencies The currencies of tokens.
     * @param fees Fees earned, currency -> amount.
     */
    struct MultiCurrencyFees{
        uint256 totalShare;
        address[] currencies;
        mapping (address => uint256) fees;
    }

    /**
     * @notice A struct containing the parameters required for the staking module.
     * 
     * @param tokens BCT Tokens stored as reserves for the curation.
     * @param fees fees earned excluding BCT, which can be withdrawn without thawing period, epoch -> MultiCurrencyFees.
     * @param reserveRatio Ratio for the bonding curve.
     * @param bst Curation token contract for this curation staking pool.
     * @param shares Shares minted totally.
     * @param delegators All delegators.
     */
    struct CurationStakingPool {
        uint256 tokens;
        uint32 reserveRatio;
        address bst;
        uint256 shares;
        mapping(uint256 => MultiCurrencyFees) fees;
        mapping(address => Delegation) delegators;
    }

    /**
     * @notice Individual delegation data of a delegator in a pool. 
     * Will auto-withdraw before updating shares.
     * 
     * @param tokens tokens be staked in curation by delegator.
     * @param shares Shares owned by a delegator in the pool
     * @param tokensLocked Tokens locked for undelegation
     * @param tokensLockedUntil Block when locked tokens can be withdrawn
     * @param lastWithdrawFeesEpoch The last withdraw fees Epoch.
     */
    struct Delegation {
        uint256 shares;
        uint256 tokensLocked;
        uint256 tokensLockedUntil;
        uint256 lastWithdrawFeesEpoch;
    }

    /**
     * @notice Stores accumulated rewards and snapshots related to a particular Curation.
     * 
     * @param accRewardsForCuration Accumulated rewards for curation 
     * @param accRewardsForCurationSnapshot Accumulated rewards for curation snapshot
     * @param accRewardsPerStakingSnapshot Accumulated rewards per staking for curation snapshot
     * @param accRewardsPerAllocatedToken Accumulated rewards per allocated token.
     */
    struct CurationReward {
        uint256 accRewardsForCuration;
        uint256 accRewardsForCurationSnapshot;
        uint256 accRewardsPerStakingSnapshot;
        uint256 accRewardsPerAllocatedToken;
    }

    /**
     * @notice Allocate tokens for the purpose of curation fees and rewards.
     * An allocation is created in the allocate() function and consumed in claim()
     * 
     * @param curator The address of curator.
     * @param curationId curation Id
     * @param recipientsMeta The snapshot of recipients from curationData.
     * @param tokens Tokens allocated to a curation, currency => tokens
     * @param createdAtEpoch Epoch when it was created
     * @param closedAtEpoch Epoch when it was closed
     * @param collectedFees Collected fees for the allocation
     * @param effectiveAllocationStake Effective allocation when closed
     * @param accRewardsPerAllocatedToken Snapshot used for reward calc
     */
    struct Allocation {
        address curator;
        uint256 curationId;
        bytes recipientsMeta;
        uint256 tokens;
        uint256 createdAtEpoch;
        uint256 closedAtEpoch;
        MultiCurrencyFees collectedFees;
        uint256 effectiveAllocationStake;
        uint256 accRewardsPerAllocatedToken;
    }

    /**
     * @notice Allocate tokens for the purpose of curation fees and rewards.
     * An allocation is created in the allocate() function and consumed in claim()
     * 
     * @param curator The address of curator.
     * @param curationId curation Id
     * @param recipientsMeta The snapshot of recipients from curationData.
     * @param tokens Tokens allocated to a curation, currency => tokens
     * @param createdAtEpoch Epoch when it was created
     * @param closedAtEpoch Epoch when it was closed
     * @param effectiveAllocationStake Effective allocation when closed
     * @param accRewardsPerAllocatedToken Snapshot used for reward calc
     */
    struct SimpleAllocation {
        address curator;
        uint256 curationId;
        bytes recipientsMeta;
        uint256 tokens;
        uint256 createdAtEpoch;
        uint256 closedAtEpoch;
        uint256 effectiveAllocationStake;
        uint256 accRewardsPerAllocatedToken;
    }

    /**
     * @notice Tracks stats for allocations closed on a particular epoch for claiming.
     * The pool also keeps tracks of total fees collected and stake used.
     * Only one rebate pool exists per epoch
     * 
     * @param fees total trade fees in the rebate pool
     * @param effectiveAllocatedStake total effective allocation of stake
     * @param claimedRewards total claimed rewards from the rebate pool
     * @param unclaimedAllocationsCount amount of unclaimed allocations
     * @param alphaNumerator numerator of `alpha` in the cobb-douglas function
     * @param alphaDenominator denominator of `alpha` in the cobb-douglas function
     */
    struct RebatePool {
        MultiCurrencyFees fees;
        mapping (address => uint256) effectiveAllocatedStake;
        MultiCurrencyFees claimedRewards;
        uint32 unclaimedAllocationsCount;
        uint32 alphaNumerator;
        uint32 alphaDenominator;
    }

    /**
     * @notice The struct for creating allocate
     * 
     * @param curator The address of curator.
     * @param curationId Curation Id.
     * @param recipientsMeta The snapshot of recipients from curationData.
     * @param currency The currency of tokens.
     * @param tokens Amount of tokens to allocate.
     * @param allocationId The allocationID will work to identify collected funds related to this allocation
     * @param metadata Metadata related to the allocation
     * @param proof A 65-bytes Ethereum signed message of `keccak256(curatorAddress,allocationID)`
     * 
     */
    struct CreateAllocateData {
        address curator;
        uint256 curationId;
        bytes recipientsMeta;
        address currency;
        uint256 tokens;
        address allocationID;
        bytes32 metadata;
        bytes proof;
    }
}