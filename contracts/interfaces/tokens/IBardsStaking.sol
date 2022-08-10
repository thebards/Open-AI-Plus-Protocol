// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBardsStaking {


    function setDefaultReserveRatio(
        uint16 _defaultReserveRatio
    ) external;

    function setMinimumCurationStaking(
        uint256 _minimumCurationStaking
    ) external;

    function setStakingTaxPercentage(
        uint16 _percentage
    ) external;

    function setCurationTokenMaster(
        address _curationTokenMaster
    ) external;

    function isCurated(uint256 _curationId) external view returns (bool);

    function getDelegatorSignal(uint256 _delegator, uint256 _curationId)
        external
        view
        returns (uint256);

    function getCurationStakingPoolSignal(
        uint256 _curationId
    ) external view returns (uint256);

    function getCurationStakingPoolTokens(
        uint256 _curationId
    ) external view returns (uint256);

    function stakingTaxPercentage(

    ) external view returns (uint16);

    function collect(
        uint256 _curationId, 
        uint256 _amount
    ) external;

	/**
     * @dev Deposit Curation Tokens in exchange for signal of a curation staking pool.
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
     * @dev Return an amount of signal to get tokens back.
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
     * @dev Calculate amount of signal that can be bought with tokens in a curation staking pool.
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
     * @dev Calculate number of tokens to get when burning signal from a curation staking pool.
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