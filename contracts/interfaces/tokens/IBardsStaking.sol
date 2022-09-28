// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import '../../utils/DataTypes.sol';

/**
 * @title IBardsStaking
 * 
 * @author TheBards Protocol
 * 
 * @notice The interface of BardsStaking
 * 
 */
interface IBardsStaking {

    /**
     * @notice initialize the contract.
     * 
     * @param _HUB The address of HUB;
     * @param _bondingCurve The address of bonding curve;
     * @param _bardsShareTokenImpl The address of bards share token;
     * @param _defaultStakingReserveRatio The default staking reserve ratio;
     * @param _stakingTaxPercentage The percentage of staking tax;
     * @param _minimumStaking The minimum staking;
     * @param _stakingAddress The fund address of staking;
     * @param _rebateAlphaNumerator The alphaNumerator of rebating;
     * @param _rebateAlphaDenominator The alphaDenominator of rebating;
     * @param _thawingPeriod The thawing period;
     */
    function initialize(
        address _HUB,
        address _bondingCurve,
        address _bardsShareTokenImpl,
        uint32 _defaultStakingReserveRatio,
        uint32 _stakingTaxPercentage,
        uint256 _minimumStaking,
        address _stakingAddress,
        uint32 _rebateAlphaNumerator,
        uint32 _rebateAlphaDenominator,
        uint32 _thawingPeriod
    ) external;

    /**
     * @notice Set the address of tokens.
     * 
     * @param _stakingAddress The address of staking tokens;
     */
    function setStakingAddress(address _stakingAddress) external;

    /**
     * @notice Set the default reserve ratio percentage for a curation pool.
     * 
     * Update the default reserver ratio to `_defaultReserveRatio`
     * @param _defaultReserveRatio Reserve ratio (in PPM)
     */
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    /**
     * @notice Set the minimum stake required to.
     * 
     * @param _minimumStaking Minimum stake
     */
    function setMinimumStaking(uint256 _minimumStaking) external;

    /**
     * @notice Set the thawing period for unstaking.
     * 
     * @param _thawingPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function setThawingPeriod(uint32 _thawingPeriod) external;

    /**
     * @notice Set the period in epochs that need to pass before fees in rebate pool can be claimed.
     * 
     * @param _channelDisputeEpochs Period in epochs
     */
    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external;

    /**
     * @notice Set the max time allowed for stake on allocations.
     * 
     * @param _maxAllocationEpochs Allocation duration limit in epochs
     */
    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    /**
     * @notice Set the rebate ratio (fees to allocated stake).
     * 
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external;

    /**
     * @notice Set a staking tax percentage to burn when staked funds are deposited.
     * @param _percentage Percentage of staked tokens to burn as staking tax
     */
    function setStakingTaxPercentage(uint32 _percentage) external;

    /**
     * @notice Set the master copy to use as clones for the Bards Share Tokens.
     * @param _bardsShareTokenImpl Address of implementation contract to use for Bards Share Tokens.
     */
    function setBardsShareTokenImpl(address _bardsShareTokenImpl) external;

    /**
     * @notice Returns whether `_curationId` is staked.
     * 
     * @param _curationId The curation ID.
     */
    function isStaked(uint256 _curationId) external view returns (bool);

    // -- Staking --

    /**
     * @notice Deposit tokens on the curation.
     * 
     * @param _curationId curation Id
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _curationId, uint256 _tokens) external returns (uint256 shareOut, uint256 stakingTax) ;

    /**
     * @notice Unstake shares from the curation stake, lock them until thawing period expires.
     * 
     * @param _curationId Curation Id to unstake
     * @param _shares Amount of shares to unstake
     */
    function unstake(uint256 _curationId, uint256 _shares) external returns(uint256);

    /**
     * @notice Withdraw staked tokens once the thawing period has passed.
     * 
     * @param _curationId curation Id
     * @param _stakeToCuration Re-delegate to new curation if non-zero, withdraw if zero address
     */ 
    function withdrawStaked(uint256 _curationId, uint256 _stakeToCuration) external returns (uint256);

    // -- Channel management and allocations --

    /**
     * @notice Allocate available tokens to a curation.
     * 
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function allocate(
        DataTypes.CreateAllocateData calldata _createAllocationData
    ) external;

    /**
     * @notice Close an allocation and free the staked tokens.
     * 
     * @param _allocationId The allocation identifier.
     * @param _stakeToCuration Restake to curation.
     */
    function closeAllocation(uint256 _allocationId, uint256 _stakeToCuration) external;

    /**
     * @notice Close multiple allocations and free the staked tokens.
     * 
     * @param _allocationIds An array of allocationId
     * @param _stakeToCurations An array of curations for restaking.
     */
    function closeAllocationMany(uint256[] calldata _allocationIds, uint256[] calldata _stakeToCurations) external;

    /**
     * @notice Close and allocate. This will perform a close and then create a new Allocation
     * atomically on the same transaction.
     * 
     * @param _closingAllocationID The identifier of the allocation to be closed
     * @param _stakeToCuration The curation of restaking.
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function closeAndAllocate(
        uint256 _closingAllocationID,
        uint256 _stakeToCuration,
        DataTypes.CreateAllocateData calldata _createAllocationData
    ) external;

    /**
     * @notice Collect fees from market and assign them to an allocation.
     * Funds received are only accepted from a valid sender.
     * To avoid reverting on the withdrawal from channel flow this function will:
     * 1) Accept calls with zero tokens.
     * 2) Accept calls after an allocation passed the dispute period, in that case, all
     *    the received tokens are burned.
     * @param _currency Currency of token to collect.
     * @param _tokens Amount of tokens to collect
     * @param _allocationId Allocation where the tokens will be assigned
     */
    function collect(address _currency, uint256 _tokens, uint256 _allocationId) external;

    /**
     * @notice Collect the delegation rewards.
     * This function will assign the collected fees to the delegation pool.
     * @param _curationId Curation to which the tokens to distribute are related
     * @param _currency The currency of token.
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     */
    function collectStakingFees(
        uint256 _curationId, 
        address _currency, 
        uint256 _tokens
    ) external;

    /**
     * @notice Claim tokens from the rebate pool.
     * 
     * @param _allocationId Allocation from where we are claiming tokens
     * @param _stakeToCuration Restake to new curation
     */
    function claim(uint256 _allocationId, uint256 _stakeToCuration) external;

    /**
     * @notice Claim tokens from the rebate pool for many allocations.
     * 
     * @param _allocationIds Array of allocations from where we are claiming tokens
     * @param _stakeToCuration Restake to new curation
     */
    function claimMany(uint256[] calldata _allocationIds, uint256 _stakeToCuration) external;

    // -- Getters and calculations --

    /**
     * @notice Return the current state of an allocation.
     * @param _allocationId Address used as the allocation identifier
     * @return AllocationState
     */
    function getAllocationState(uint256 _allocationId) external view returns (DataTypes.AllocationState);

    /**
     * @notice Return if allocationId is used.
     * 
     * @param _allocationId Address used as signer for an allocation
     * @return True if allocationId already used
     */
    function isAllocation(uint256 _allocationId) external view returns (bool);

    /**
     * @notice Return the total amount of tokens allocated to curation.
     * 
     * @param _allocationId allocation Id
     * @param _currency The address of currency
     * @return Total tokens allocated to curation
     */
    function getFeesCollectedInAllocation(
        uint256 _allocationId, 
        address _currency
    )
        external
        view
        returns (uint256);

    /**
     * @notice Return the total amount of tokens allocated to curation.
     * 
     * @param _curationId _curationId
     * @return Total tokens allocated to curation
     */
    function getCurationAllocatedTokens(uint256 _curationId)
        external
        view
        returns (uint256);

    /**
     * @notice Get the address of staking tokens.
     * 
     * @return The address of Staking tokens.
     */
    function getStakingAddress() 
        external
        view
        returns (address);

    /**
     * @notice Get the total staking tokens.
     * 
     * @return The total Staking tokens.
     */
    function getTotalStakingToken() 
        external
        view
        returns (uint256);

    function getSimpleAllocation(
        uint256 _allocationId
    ) 
        external 
        view 
        returns (DataTypes.SimpleAllocation memory);

    /**
     * @notice Get the reserveRatio of curation.
     *
     * @param _curationId The curation ID
     * 
     * @return reserveRatio The reserveRatio of curation.
     */
    function getReserveRatioOfCuration(uint256 _curationId) 
        external
        view
        returns (uint32 reserveRatio);

    /**
     * @notice Returns amount of staked BCT tokens ready to be withdrawn after thawing period.
     * @param _curationId curation Id.
     * @param _delegator Delegator owning the share tokens
     * @return Are there any withdrawable tokens.
     */
    function getWithdrawableBCTTokens(uint256 _curationId, address _delegator)
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of share a delegator has in a curation staking pool.
     * 
     * @param _delegator Delegator owning the share tokens
     * @param _curationId curation Id.
     * 
     * @return Amount of share owned by a delegator for the curation
     */
    function getDelegatorShare(
        address _delegator, 
        uint256 _curationId
    )
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of share in a curation staking pool.
     * 
     * @param _curationId curation Id.
     * 
     * @return Amount of share minted for the curation
     */
    function getStakingPoolShare(uint256 _curationId) 
        external 
        view 
        returns (uint256);

    /**
     * @notice Get the amount of share in a curation staking pool.
     * 
     * @param _curationId curation Id.
     * 
     * @return Amount of share minted for the curation
     */
    function getStakingPoolToken(uint256 _curationId) 
        external 
        view 
        returns (uint256);

    /**
     * @notice Return whether the delegator has staked to the curation.
     * 
     * @param _curationId  Curation Id where funds have been staked
     * @param _delegator Address of the delegator
     * @return True if delegator of curation
     */
    function isDelegator(uint256 _curationId, address _delegator) external view returns (bool);

    /**
     * @notice Return whether the seller is one of the stakeholders of curation.
     * 
     * @param _allocationId _allocationId
     * @param _seller Address of the seller of curation NFT
     * @return True if delegator of curation
     */
    function isSeller(uint256 _allocationId, address _seller) external view returns (bool);

    /**
     * @notice Calculate amount of share that can be bought with tokens in a staking pool.
     * 
     * @param _curationId Curation to mint share
     * @param _tokens Amount of tokens used to mint share
     * @return Amount of share that can be bought with tokens
     */
    function tokensToShare(uint256 _curationId, uint256 _tokens)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate number of tokens to get when burning shares from a staking pool.
     * 
     * @param _curationId Curation to burn share
     * @param _shares Amount of share to burn
     * 
     * @return Amount of tokens to get for an amount of shares
     */
    function shareToTokens(uint256 _curationId, uint256 _shares)
        external
        view
        returns (uint256);
}