// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
     * @notice Set the default staking reserve ratio percentage for a curation staking pool.
     * @notice Update the default reserver ratio to `_defaultReserveRatio`
     * @param _defaultStakingReserveRatio Reserve ratio (in PPM)
     */
    function setDefaultStakingReserveRatio(
        uint32 _defaultStakingReserveRatio
    ) external;

    /**
     * @notice Set the minimum staking amount for delegators.
     * @notice Update the minimum staking amount to `_minimumCurationStaking`
     * @param _minimumCurationStaking Minimum amount of tokens required deposit
     */
    function setMinimumCurationStaking(
        uint256 _minimumCurationStaking
    ) external;

    /**
     * @notice Set the staking tax percentage to charge when a delegator deposits BCT tokens.
     * @param _percentage Staking tax percentage charged when depositing BCT tokens
     */
    function setStakingTaxPercentage(
        uint32 _percentage
    ) external;

    /**
     * @notice Set the master copy to use as clones for the curation staking token.
     * @param _curationStakingTokenMaster Address of implementation contract to use for curation staking tokens
     */
    function setCurationStakingTokenMaster(
        address _curationStakingTokenMaster
    ) external;

    /**
     * @notice Check if any BCT tokens are deposited for a curation.
     * @param _curationId curation ID to check if curated
     * @return True if staked
     */
    function isStaked(uint256 _curationId) external view returns (bool);

    /**
     * @notice Get the amount of signal a delegator has in a curation staking pool.
     * @param _delegator Delegator owning the signal tokens
     * @param _curationId Curation Id of curation staking pool
     * @return Amount of signal owned by a delegator for the curation.
     */
    function getDelegatorSignal(uint256 _delegator, uint256 _curationId)
        external
        view
        returns (uint256);

    /**
     * @dev Get the amount of signal in a curation staking pool.
     * @param _curationId Curation Id of curation staking pool
     * @return Amount of signal minted for the curation
     */
    function getCurationStakingPoolSignal(
        uint256 _curationId
    ) external view returns (uint256);

    /**
     * @dev Get the amount of token reserves in a curation staking pool.
     * @param _curationId Curation Id of curation staking pool
     * @return Amount of token reserves in the curation staking pool
     */
    function getCurationStakingPoolTokens(
        uint256 _curationId
    ) external view returns (uint256);

    /**
     * @notice Assign Bards Curation Tokens earned as fees to the curation staking pool reserve.
     * This function can only be called by the Hub contract and will do the bookeeping of
     * transferred tokens into this contract.
     * @param _curationId CurationId where funds should be allocated as reserves
     * @param _amount Amount of Bards Curation Tokens to add to reserves
     */
    function earn(
        uint256 _curationId, 
        uint256 _amount
    ) external;

	/**
     * @notice Deposit Curation Tokens in exchange for signal of a curation staking pool.
     * @param _curationId The curation ID from where to mint signal
     * @param _tokensIn Amount of Graph Tokens to deposit
     * @param _signalOutMin Expected minimum amount of signal to receive
     * @return Signal minted and deposit tax
     */
    function mint(
        uint256 _curationId,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external returns (uint256, uint256);
	
    /**
     * @notice Return an amount of signal to get tokens back.
     * @notice Burn _signal from the SubgraphDeployment curation pool
     * @param _curationId Curation the curator is returning signal
     * @param _signalIn Amount of signal to return
     * @param _tokensOutMin Expected minimum amount of tokens to receive
     * @return Tokens returned
     */
	function burn(
        uint256 _curationId,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external returns (uint256);

    /**
     * @notice Calculate amount of signal that can be bought with tokens in a curation staking pool.
     * This function considers and excludes the deposit tax.
     * @param _curationId A curation to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought and tokens subtracted for the tax
     */
	function tokensToSignal(
		uint256 _curationId, 
		uint256 _tokensIn
	)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate number of tokens to get when burning signal from a curation staking pool.
     * @param _curationId A curation to burn signal
     * @param _signalIn Amount of signal to burn
     * @return Amount of tokens to get for an amount of signal
     */
    function signalToTokens(
		uint256 _curationId, 
		uint256 _signalIn
	)
        external
        view
        returns (uint256);
}