// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title RewardManager Interface
 * 
 * @author Thebards Protocol
 * 
 * @notice The interface of RewardManager contract.
 */
interface IRewardsManager {
	// -- Config --

	  /**
     * @notice Sets the issuance rate.
     * The issuance rate is defined as a percentage increase of the total supply per block.
     * This means that it needs to be greater than 1.0, any number under 1.0 is not
     * allowed and an issuance rate of 1.0 means no issuance.
     * To accommodate a high precision the issuance rate is expressed in wei.
     * @param _issuanceRate Issuance rate expressed in wei
     */
    function setIssuanceRate(
        uint256 _issuanceRate
    ) external;


    /**
     * @notice Set inflationChange. Only callable by gov
     * @param _inflationChange Inflation change as a percentage of total token supply
     */
    function setInflationChange(
        uint256 _inflationChange
    ) external;

    /**
     * @notice Set targetBondingRate. Only callable by gov
     * @param _targetBondingRate Target bonding rate as a percentage of total bonded tokens / total token supply
     */
    function setTargetBondingRate(
        uint256 _targetBondingRate
    ) external;

	  /**
     * @notice Sets the minimum staked tokens on a curation to start accruing rewards.
     * Can be set to zero which means that this feature is not being used.
     * @param _minimumStakeingToken Minimum signaled tokens
     */
    function setMinimumStakingToken(
        uint256 _minimumStakeingToken
    ) external;

    /**
     * @notice Denies to claim rewards for a curation.
     * @param _curationId curation ID
     * @param _deny Whether to set the curation as denied for claiming rewards or not
     */
    function setDenied(
        uint256 _curationId, 
        bool _deny
    ) external;

    /**
     * @notice Denies to claim rewards for multiple curations.
     * @param _curationIds Array of curation ID
     * @param _deny Array of denied status for claiming rewards for each curation
     */
    function setDeniedMany(
        uint256[] calldata _curationIds, 
        bool[] calldata _deny
    ) external;

    /**
     * @notice Tells if curation is in deny list
     * @param _curationId Curation ID to check
     * @return Whether the curation is denied for claiming rewards or not
     */
    function isDenied(
        uint256 _curationId
    ) 
      external 
      view 
      returns (bool);

	/**
     * @notice Gets the issuance of rewards per staking since last updated.
     *
     * Compound interest formula: `a = p(1 + r/n)^nt`
     * The formula is simplified with `n = 1` as we apply the interest once every time step.
     * The `r` is passed with +1 included. So for 10% instead of 0.1 it is 1.1
     * The simplified formula is `a = p * r^t`
     *
     * Notation:
     * t: time steps are in blocks since last updated
     * p: total supply of BCT tokens
     * a: inflated amount of total supply for the period `t` when interest `r` is applied
     * x: newly accrued rewards token for the period `t`
     *
     * @return newly accrued rewards per signal since last update
     */
    function getNewRewardsPerStaking() 
        external 
        view 
        returns (uint256);

    /**
     * @notice Gets the currently accumulated rewards per staking.
     * @return Currently accumulated rewards per staking
     */
    function getAccRewardsPerStaking() 
        external 
        view 
        returns (uint256);

    /**
     * @notice Gets the accumulated rewards for the curation.
     * @param _curationId Curation Id
     * @return Accumulated rewards for curation
     */
    function getAccRewardsForCuration(
        uint256 _curationId
    )
        external
        view
        returns (uint256);

    /**
     * @notice Gets the accumulated rewards per allocated token for the curation.
     * @param _curationId Curation Id
     * @return Accumulated rewards per allocated token for the curation
     * @return Accumulated rewards for curation
     */
    function getAccRewardsPerAllocatedToken(
        uint256 _curationId
    )
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Calculate current rewards for a given allocation on demand.
     * @param _allocationId Allocation
     * @return Rewards amount for an allocation
     */
    function getRewards(
        uint256 _allocationId
    ) 
      external 
      view 
      returns (uint256);

    /**
     * @notice Updates the accumulated rewards per staking and save checkpoint block number.
     * Must be called before `issuanceRate` or `total staked BCT` changes
     * Called from the BardsStaking contract on mint() and burn()
     * @return Accumulated rewards per staking
     */
    function updateAccRewardsPerStaking() 
        external 
        returns (uint256);

    /**
     * Set IssuanceRate based upon the current bonding rate and target bonding rate
     */
    function onUpdateIssuanceRate() external;

    /**
     * @notice Pull rewards from the contract for a particular allocation.
     * This function can only be called by the BardsStaking contract.
     * This function will mint the necessary tokens to reward based on the inflation calculation.
     * @param _allocationId Allocation
     * @return Assigned rewards amount
     */
    function takeRewards(
        uint256 _allocationId
    ) 
      external 
      returns (uint256);

    // -- Hooks --

    /**
     * @notice Triggers an update of rewards for a curation.
     * Must be called before `staked BCT` on a curation changes.
     * Note: Hook called from the BardsStaking contract on mint() and burn()
     * @param _curationId Curation Id
     * @return Accumulated rewards for curation
     */
    function onCurationStakingUpdate(
        uint256 _curationId
    ) 
      external 
      returns (uint256);

    /**
     * @notice Triggers an update of rewards for a curation.
     * Must be called before allocation on a curation changes.
     * NOTE: Hook called from the BardStaking contract on allocate() and closeAllocation()
     *
     * @param _curationId Curation Id
     * @return Accumulated rewards per allocated token for a curation
     */
    function onCurationAllocationUpdate(
        uint256 _curationId
    ) 
      external 
      returns (uint256);
	
}