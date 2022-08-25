// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
     * @notice Set the default reserve ratio percentage for a curation pool.
     * 
     * Update the default reserver ratio to `_defaultReserveRatio`
     * @param _defaultReserveRatio Reserve ratio (in PPM)
     */
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    /**
     * @notice Set the minimum stake required to.
     * 
     * @param _minimumStake Minimum stake
     */
    function setMinimumStake(uint256 _minimumStake) external;

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
     * @dev Set the master copy to use as clones for the Bards Share Tokens.
     * @param _bardsShareTokenImpl Address of implementation contract to use for Bards Share Tokens.
     */
    function setBardsShareTokenImpl(address _bardsShareTokenImpl) external;

    // -- Operation --

    /**
     * @notice Authorize or unauthorize an address to be an operator.
     * @param _operator Address to authorize
     * @param _allowed Whether authorized or not
     */
    function setOperator(address _operator, bool _allowed) external;

    /**
     * @notice Return true if operator is allowed for the bards.
     * 
     * @param _operator Address of the operator
     * @param _theBards Address of the bards
     */
    function isOperator(address _operator, address _theBards) external view returns (bool);

    // -- Staking --

    /**
     * @notice Deposit tokens on the curation.
     * 
     * @param _curationId curation Id
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _curationId, uint256 _tokens) external returns(uint256, uint256);

    /**
     * @notice Unstake shares from the curation stake, lock them until thawing period expires.
     * 
     * @param _curationId Curation Id to unstake
     * @param _shares Amount of shares to unstake
     */
    function unstake(uint256 _curationId, uint256 _shares) external;

    /**
     * @notice Withdraw tokens once the thawing period has passed.
     */
    function withdraw() external;

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
     * @param _allocationID The allocation identifier
     */
    function closeAllocation(address _allocationID) external;

    /**
     * @notice Close multiple allocations and free the staked tokens.
     * 
     * @param _allocationIDs An array of allocationID
     */
    function closeAllocationMany(address[] calldata _allocationIDs) external;

    /**
     * @notice Close and allocate. This will perform a close and then create a new Allocation
     * atomically on the same transaction.
     * 
     * @param _closingAllocationID The identifier of the allocation to be closed
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function closeAndAllocate(
        address _closingAllocationID,
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
     * @param _allocationID Allocation where the tokens will be assigned
     */
    function collect(address _currency, uint256 _tokens, address _allocationID) external;

    /**
     * @notice Claim tokens from the rebate pool.
     * 
     * @param _allocationID Allocation from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to curation
     */
    function claim(address _allocationID, bool _restake) external;

    /**
     * @notice Claim tokens from the rebate pool for many allocations.
     * 
     * @param _allocationIDs Array of allocations from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to curation
     */
    function claimMany(address[] calldata _allocationIDs, bool _restake) external;

    // -- Getters and calculations --

    /**
     * @notice Getter that returns if a curation has any stake.
     * @param _curationId Address of the indexer
     * @return True if curation has staked tokens
     */
    function hasStake(uint256 _curationId) external view returns (bool);

    /**
     * @dev Return the current state of an allocation.
     * @param _allocationID Address used as the allocation identifier
     * @return AllocationState
     */
    function getAllocationState(address _allocationID) external view returns (DataTypes.AllocationState);

    /**
     * @notice Return if allocationID is used.
     * 
     * @param _allocationID Address used as signer for an allocation
     * @return True if allocationID already used
     */
    function isAllocation(address _allocationID) external view returns (bool);

    /**
     * @notice Return the total amount of tokens allocated to curation.
     * 
     * @param _curationId curationId
     * @return Total tokens allocated to curation
     */
    function getCurationAllocatedTokens(uint256 _curationId)
        external
        view
        returns (uint256);

    /**
     * @notice Returns amount of staked BCT tokens ready to be withdrawn after thawing period.
     * @param _curationId curation Id.
     * @param _delegator Delegator owning the share tokens
     * @return Are there any withdrawable tokens.
     */
    function getWithdraweableBCTTokens(uint256 _curationId, address _delegator)
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
     * @param _currency The currency of token.
     * 
     * @return Amount of share minted for the curation
     */
    function getStakingPoolToken(uint256 _curationId, address _currency) 
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
     * @param _currency The currency of token return
     * 
     * @return Amount of tokens to get for an amount of shares
     */
    function shareToTokens(uint256 _curationId, uint256 _shares, address _currency)
        external
        view
        returns (uint256);
}