// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/tokens/IBardsStaking.sol';
import '../storages/BardsStakingStorage.sol';
import './BardsShareToken.sol';
import './BardsCurationToken.sol';
import '../../utils/DataTypes.sol';
import '../../utils/Errors.sol';
import '../../utils/Events.sol';
import '../../utils/Constants.sol';
import '../../utils/BancorFormula.sol';
import '../../interfaces/tokens/IBardsShareToken.sol';
import '../../interfaces/tokens/IBardsCurationToken.sol';
import '../govs/ContractRegistrar.sol';
import '../govs/BardsPausable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Curation contract
 * 
 * @author TheBards Protocol
 * 
 * @notice Allows delegator to signal on curations by staking Bards Curation Tokens (BCT). 
 * Additionally, delegator will earn a share of all the curation share revenue that the curation generates.
 * A delegator deposit goes to a curation staking pool along with the deposits of other delegators,
 * only one such pool exists for each curation.
 * The contract mints Bards Curation Shares (BCS) according to a bonding curve for each individual
 * curation staking pool where BCT is deposited.
 * Holders can burn BCS using this contract to get BCT tokens back according to the
 * bonding curve.
 */
contract BardsStaking is IBardsStaking, BardsStakingStorage, ContractRegistrar, BardsPausable {
	using SafeMath for uint256;
    using Rebates for Rebates.Pool;
	
	/**
     * @dev Initialize this contract.
     */
    function initialize(
		address _HUB,
        address _bondingCurve,
        address _bardsShareTokenImpl,
        uint32 _defaultStakingReserveRatio,
        uint32 _stakingTaxPercentage,
        uint256 _minimumCurationStaking
    ) external {
		if (_HUB == address(0)) revert Errors.InitParamsInvalid();
        require(_bondingCurve != address(0), "Bonding curve must be set");
        bondingCurve = _bondingCurve;
		ContractRegistrar._initialize(_HUB);
        // Settings
		_setBardsShareTokenImpl(_bardsShareTokenImpl);
        _setDefaultReserveRatio(_defaultStakingReserveRatio);
        _setStakingTaxPercentage(_stakingTaxPercentage);
        _setMinimumStaking(_minimumCurationStaking);
    }

    /// @inheritdoc IBardsStaking
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) 
		external 
		override 
	onlyHub {
        _setDefaultReserveRatio(_defaultReserveRatio);
    }

    /// @inheritdoc IBardsStaking
    function setMinimumStaking(uint256 _minimumStake)
        external
        override
    onlyHub{
        _setMinimumStaking(_minimumStake);
    }

    /// @inheritdoc IBardsStaking
    function setThawingPeriod(uint32 _thawingPeriod)
        external
        override
    onlyHub{
        _setThawingPeriod(_thawingPeriod);
    }

    /// @inheritdoc IBardsStaking
    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) 
        external 
        override 
    onlyHub {
        _setChannelDisputeEpochs(_channelDisputeEpochs);
    }

    /// @inheritdoc IBardsStaking
    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) 
        external 
        override 
    onlyHub {
        _setMaxAllocationEpochs(_maxAllocationEpochs);
    }

    /**
     * @dev Set the rebate ratio (fees to allocated stake).
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator)
        external
        override
    onlyHub {
        _setRebateRatio(_alphaNumerator, _alphaDenominator);
    }

    /// @inheritdoc IBardsStaking
	function setStakingTaxPercentage(uint32 _percentage) 
		external 
		override 
	onlyHub {
        _setStakingTaxPercentage(_percentage);
    }

    /// @inheritdoc IBardsStaking
    function setBardsShareTokenImpl(address _bardsShareTokenImpl) 
		external 
		override 
	onlyHub {
        _setBardsShareTokenImpl(_bardsShareTokenImpl);
    }

    /// @inheritdoc IBardsStaking
    function setOperator(address _operator, bool _allowed) external override {
        require(_operator != msg.sender, "operator == sender");
        operatorAuth[msg.sender][_operator] = _allowed;
        emit Events.OperatorSet(msg.sender, _operator, _allowed, block.timestamp);
    }

    /// @inheritdoc IBardsStaking
    function isOperator(address _operator, address _theBards) 
        public 
        view 
        override 
    returns (bool) {
        return operatorAuth[_indexer][_operator];
    }

    /// @inheritdoc IBardsStaking
	function stake(
        uint256 _curationId,
        uint256 _tokens
    ) 
        external 
        override 
    returns (uint256, uint256) {
        address delegator = msg.sender;
        TokenUtils.pullTokens(bardsCurationToken(), delegator, _tokens);

        return _stake(_curationId, _tokens, delegator);
    }

    /**
     * @notice stake tokens to a curation.

     * @param _curationId Id of the curation to stake tokens to
     * @param _tokens Amount of tokens to stake
     * @param _delegator Address of the delegator
     * 
     * @return Amount of shares issued of the staking pool
     */
    function _stake(
        uint256 _curationId,
        uint256 _tokens,
        address _delegator
    ) 
        private 
    returns (uint256, uint256) {
        // Need to deposit some funds
        require(_tokens > 0, "Cannot deposit zero tokens");

        // Exchange BCT tokens for BST of the curation staking pool
        (uint256 shareOut, uint256 stakingTax) = tokensToShare(_curationId, _tokens);

        // Slippage protection
        // require(shareOut >= _shareOutMin, "Slippage protection");

        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];

        // If it hasn't been curated before then initialize the curve
        if (!isStaked(_curationId)) {
            stakingPool.reserveRatio = defaultStakingReserveRatio;

            // If no signal token for the pool - create one
            if (stakingPool.bst == address(0)) {
                // Use a minimal proxy to reduce gas cost
                IBardsShareToken bst = IBardsShareToken(Clones.clone(bardsShareTokenImpl));
                bst.initialize(address(this));
                stakingPool.bst = bst;
            }
        }

        // Trigger update rewards calculation snapshot
        _updateRewardsWithStaking(_curationId);

        // Transfer tokens from the delegator to this contract
        // Burn the curation tax
        // NOTE: This needs to happen after _updateRewards snapshot as that function
        // is using balanceOf(curation)
        IBardsCurationToken _bardsCurationToken = bardsCurationToken();
        TokenUtils.burnTokens(_bardsCurationToken, stakingTax);

        // Update curation staking pool
        stakingPool.tokens[address(_bardsCurationToken)] = stakingPool.tokens[address(_bardsCurationToken)]
            .add(_tokens.sub(stakingTax));

        IBardsShareToken(stakingPool.bst).mint(_delegator, shareOut);
        // Update the individual delegation
        DataTypes.Delegation storage delegation = stakingPool.delegators[_delegator];
        delegation.shares = delegation.shares.add(shareOut);

        emit Events.CurationPoolStaked(
            _delegator, 
            _curationId, 
            _tokens, 
            shareOut, 
            stakingTax, 
            block.timestamp
        );

        return (shareOut, stakingTax);
    }

    /// @inheritdoc IBardsStaking
    function unstake(
        uint256 _curationId,
        uint256 _shares,
        address _delegator
    ) external override returns (uint256) {
        return _unstake(_curationId, _shares, msg.sender);
    }

    /**
     * @notice Unstake tokens from an curation.
     * 
     * @param _curationId Curation Id
     * @param _shares Amount of shares to return and unstake tokens
     * @param _delegator Address of the delegator
     * 
     * @return Amount of tokens returned for the shares of the staking pool
     */
    function _unstake(
        uint256 _curationId,
        uint256 _shares,
        address _delegator
    ) private returns (uint256) {
        // Validations
        require(_shares > 0, "Cannot burn zero signal");
        require(
            getDelegatorShare(delegator, _curationId) >= _shares,
            "Cannot burn more share than you own"
        );

        // Slippage protection
        // require(tokensOut >= _tokensOutMin, "Slippage protection");

        // Trigger update rewards calculation
        _updateRewardsWithStaking(_curationId);

        // Update curation pool
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        // Update the individual delegation
        DataTypes.Delegation storage delegation = stakingPool.delegators[_delegator];

        // Withdraw tokens if available
        if (getWithdraweableBCTTokens(_curationId, _delegator) > 0) {
            _withdrawDelegated(_delegator, _curationId, 0);
        }

        // burn share
        IBardsShareToken(stakingPool.bst).burnFrom(_delegator, _shares);
        // update the delegation
        delegation.shares = delegation.shares.sub(_shares);
        delegation.tokensLockedUntil = epochManager().currentEpoch().add(thawingPeriod);

        address[] currencies = stakingPool.currencies;
        uint256 tokensOut;
        for(uint256 i = 0; i <= currencies.length; i++){
            address curCurrency = currencies[i];
            // Get the amount of tokens to refund based on returned shares
            tokensOut = shareToTokens(_curationId, _shares, curCurrency);
            if (tokensOut <= 0){
                continue;
            }
            stakingPool.tokens[curCurrency] = stakingPool.tokens[curCurrency].sub(tokensOut);
            // Update the delegation
            delegation.tokensLocked[curCurrency] = delegation.tokensLocked[curCurrency].add(tokensOut);
        }
        emit Events.StakeDelegatedLocked(
            _curationId, 
            _delegator, 
            _shares, 
            delegation.tokensLockedUntil, 
            block.timestamp
        );

        return tokensOut;
    }

    /// @inheritdoc IBardsStaking
    function allocate(
        DataTypes.CreateAllocateData calldata _createAllocationData
    ) 
        external 
        override 
        whenNotPaused 
    {
        _allocate(msg.sender, _createAllocationData);
    }

    /// @inheritdoc IBardsStaking
    function closeAllocation(address _allocationID) 
        external 
        override 
        whenNotPaused 
    {
        _closeAllocation(_allocationID);
    }

    /// @inheritdoc IBardsStaking
    function closeAllocationMany(address[] calldata _allocationIDs)
        external
        override
        whenNotPaused 
    {
        for (uint256 i = 0; i < _allocationIDs.length; i++) {
            _closeAllocation(_allocationIDs[i]);
        }
    }

    /// @inheritdoc IBardsStaking
    function closeAndAllocate(
        address _closingAllocationID,
        DataTypes.CreateAllocateData calldata _createAllocationData
    ) 
        external 
        override 
        whenNotPaused 
    {
        _closeAllocation(_closingAllocationID);
        _allocate(msg.sender, _createAllocationData);
    }

    /// @inheritdoc IBardsStaking
    function collect(
        address _currency, 
        uint256 _tokens, 
        address _allocationID
    ) 
        external 
        override
    {
        // Allocation identifier validation
        require(_allocationID != address(0), "!alloc");

        // Allocation must exist
        DataTypes.AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState != DataTypes.AllocationState.Null, "!collect");

        // Get allocation
        DataTypes.Allocation storage alloc = allocations[_allocationID];
        uint256 queryFees = _tokens;
        uint256 curationFees = 0;

        // Process query fees only if non-zero amount
        if (queryFees > 0) {
            // // Pull tokens to collect from the authorized sender
            // IERC20 _ierc20 = IERC20(_currency);
            // TokenUtils.pullTokens(_ierc20, msg.sender, _tokens);

            // Add funds to the allocation
            alloc.collectedFees[_currency] = alloc.collectedFees[_currency].add(queryFees);

            // When allocation is closed redirect funds to the rebate pool
            // This way we can keep collecting tokens even after the allocation is closed and
            // before it gets to the finalized state.
            if (allocState == DataTypes.AllocationState.Closed) {
                DataTypes.RebatePool storage rebatePool = rebates[alloc.closedAtEpoch];
                rebatePool.fees[_currency] = rebatePool.fees[_currency].add(queryFees);
            }
        }

        emit Events.AllocationCollected(
            alloc.indexer,
            subgraphDeploymentID,
            epochManager().currentEpoch(),
            _tokens,
            _allocationID,
            msg.sender,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsStaking
    function claim(
        address _allocationID, 
        bool _restake
    ) 
        external 
        override 
        whenNotPaused 
    {
        _claim(_allocationID, _restake);
    }

    /// @inheritdoc IBardsStaking
    function claimMany(address[] calldata _allocationIDs, bool _restake)
        external
        override
        whenNotPaused
    {
        for (uint256 i = 0; i < _allocationIDs.length; i++) {
            _claim(_allocationIDs[i], _restake);
        }
    }

    /// @inheritdoc IBardsStaking
    function getWithdraweableBCTTokens(uint256 _curationId, address _delegator)
        public
        view
        returns (uint256)
    {
        // Get the delegation pool of the indexer
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        DataTypes.Delegation storage _delegation = stakingPool.delegators[_delegator];
        // There must be locked tokens and period passed
        uint256 currentEpoch = epochManager().currentEpoch();
        if (_delegation.tokensLockedUntil > 0 && currentEpoch >= _delegation.tokensLockedUntil) {
            return _delegation.tokensLocked[address(bardsCurationToken())];
        }
        return 0;
    }

    /// @inheritdoc IBardsStaking
    function isStaked(uint256 _curationId) 
		public 
		view 
		override 
	    returns (bool) 
    {
        return _stakingPools[_curationId].tokens[address(bardsCurationToken())] > 0;
    }

    /// @inheritdoc IBardsStaking
    function getAllocationState(address _allocationID)
        external
        view
        override
        returns (AllocationState)
    {
        return _getAllocationState(_allocationID);
    }

    /// @inheritdoc IBardsStaking
    function tokensToShare(uint256 _curationId, uint256 _tokens)
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 stakingTax = _tokens.mul(uint256(stakingTaxPercentage)).div(Constants.MAX_BPS);
        uint256 shareOut = _tokensToSignal(_curationId, _tokens.sub(stakingTax));
        return (shareOut, stakingTax);
    }

    /// @inheritdoc IBardsStaking
    function withdrawStaked(
        uint256 _curationId,
        uint256 _stakeToCuration
    ) 
        public
        override
    {
        _withdrawStaked(msg.sender, _curationId, _stakeToCuration);
    }

    /**
     * @notice Withdraw staked tokens once the thawing period has passed.
     * @param _delegator Delegator that is withdrawing tokens
     * @param _curationId Withdraw available tokens staked to curation
     * @param _stakeToCuration Re-stake to other curation if non-zero, withdraw if zero address
     */
    function _withdrawStaked(
        address _delegator,
        uint256 _curationId,
        uint256 _stakeToCuration
    ) private returns (uint256) {
        // Get the delegation pool of the indexer
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        DataTypes.Delegation storage delegation = stakingPool.delegators[_delegator];

        // Validation
        uint256 tokensToWithdraw = getWithdraweableBCTTokens(_curationId, _delegator);
        require(tokensToWithdraw > 0, "!tokens");

        // Reset lock
        delegation.tokensLockedUntil = 0;

        emit Events.StakeDelegatedWithdrawn(_curationId, _delegator, tokensToWithdraw, block.timestamp);

        // -- Interactions --
        address[] currencies = stakingPool.currencies;
        for(i = 0; i < currencies.length; i++){
            if (delegation.tokensLocked[curCurrency] <= 0){
                continue;
            }
            address curCurrency = currencies[i];
            if (curCurrency == address(bardsCurationToken())){
                if (_stakeToCuration != 0) {
                    // Re-delegate tokens to a new curation
                    _stake(_stakeToCuration, tokensToWithdraw, _delegator);
                }
            }
            // Return tokens to the delegator
            TokenUtils.pushTokens(IERC20(curCurrency), _delegator, delegation.tokensLocked[curCurrency]);
            // Reset lock
            delegation.tokensLocked[curCurrency] = 0;
        }
        

        return tokensToWithdraw;
    }

    /**
     * @dev Calculate amount of signal that can be bought with tokens in a curation staking pool.
     * @param _curationId Curation to mint share
     * @param _tokens Amount of tokens used to mint share
     * @return Amount of share that can be bought with tokens
     */
    function _tokensToSignal(uint256 _curationId, uint256 _tokens)
        private
        view
        returns (uint256)
    {
        // Get curation pool tokens and signal
        DataTypes.StakingStruct storage stakingPool = _stakingPools[_curationId];
        address currency = address(bardsCurationToken());

        // Init curation pool
        if (stakingPool.tokens[currency] == 0) {
            require(
                _tokens >= minimumStaking,
                "Curation staking is below minimum required"
            );
            return
                BancorFormula(bondingCurve)
                    .calculatePurchaseReturn(
                        Constants.SIGNAL_PER_MINIMUM_DEPOSIT,
                        minimumStaking,
                        defaultStakingReserveRatio,
                        _tokens.sub(minimumStaking)
                    )
                    .add(Constants.SIGNAL_PER_MINIMUM_DEPOSIT);
        }

        return
            BancorFormula(bondingCurve)
                .calculatePurchaseReturn(
                    getStakingPoolShare(_curationId),
                    stakingPool.tokens[currency],
                    stakingPool.reserveRatio,
                    _tokens
            );
    }

    /// @inheritdoc IBardsStaking
    function shareToTokens(uint256 _curationId, uint256 _shares, address _currency)
        public
        view
        override
        returns (uint256)
    {
        DataTypes.StakingStruct storage stakingPool = _stakingPools[_curationId];
        uint256 stakingPoolShare = getStakingPoolShare(_curationId);

        require(
            stakingPool.tokens[_currency] > 0,
            "Curation must be built to perform calculations"
        );
        require(
            stakingPoolShare >= _shares,
            "Share must be above or equal to signal issued in the curation staking pool"
        );

        return
            BancorFormula(bondingCurve).calculateSaleReturn(
                stakingPoolShare,
                stakingPool.tokens[_currency],
                stakingPool.reserveRatio,
                _shares
            );
    }

    /// @inheritdoc IBardsStaking
    function getDelegatorShare(
        address _delegator, 
        uint256 _curationId
    )
        public
        view
        override
        returns (uint256)
    {
        address bst = _stakingPools[_curationId].bst;
        return (bst == address(0)) ? 0 : IBardsShareToken(bst).balanceOf(_delegator);
    }

    /// @inheritdoc IBardsStaking
    function getStakingPoolShare(uint256 _curationId)
        public
        view
        override
        returns (uint256)
    {
        address bst = _stakingPools[_curationId].bst;
        return (bst == address(0)) ? 0 : IBardsShareToken(bst).totalSupply();
    }

    /// @inheritdoc IBardsStaking
    function getStakingPoolToken(uint256 _curationId, address _currency)
        external
        view
        override
        returns (uint256)
    {
        return _stakingPools[_curationId].tokens[_currency];
    }

	/**
     * @notice Internal: Set the staking tax percentage to charge when a delegator deposits BCT tokens.
     * 
     * @param _newPercentage Staking tax percentage charged when depositing BCT tokens
     */
    function _setStakingTaxPercentage(uint32 _newPercentage) private {
        require(
            _newPercentage <= Constants.MAX_BPS,
            "Staking tax percentage must be below or equal to MAX_BPS"
        );

		uint32 prevStakingTaxPercentage = stakingTaxPercentage;
        stakingTaxPercentage = _newPercentage;
        emit Events.StakingTaxPercentageSet(
			prevStakingTaxPercentage, 
			_newPercentage, 
			block.timestamp
		);
    }

	/**
     * @dev Internal: Set the default reserve ratio percentage for a curation staking pool.
     * @notice Update the default reserver ratio to `_defaultReserveRatio`
     * @param _newDefaultStakingReserveRatio Reserve ratio (in PPM)
     */
    function _setDefaultReserveRatio(
		uint32 _newDefaultStakingReserveRatio
	) private {
        // Reserve Ratio must be within 0% to 100% (inclusive, in PPM)
        require(_newDefaultStakingReserveRatio > 0, "Default reserve ratio must be > 0");
        require(
            _newDefaultStakingReserveRatio <= Constants.MAX_BPS,
            "Default reserve ratio cannot be higher than MAX_PPM"
        );
		uint32 prevDefaultStakingReserveRatio = defaultStakingReserveRatio;
        defaultStakingReserveRatio = _newDefaultStakingReserveRatio;
        emit Events.DefaultStakingReserveRatioSet(
			prevDefaultStakingReserveRatio, 
			_newDefaultStakingReserveRatio, 
			block.timestamp
		);
    }

    /**
     * @dev Internal: Set the minimum staking amount for delegators.
     * @notice Update the minimum staking amount to `minimumStaking`
     * @param _newMinimumStaking Minimum amount of tokens required staking
     */
    function _setMinimumStaking(
		uint256 _newMinimumStaking
	) private {
        require(_newMinimumStaking > 0, "Minimum curation deposit cannot be 0");

		uint256 prevMinimumStaking = minimumStaking;	
        minimumStaking = _newMinimumStaking;

        emit Events.MinimumCurationStakingSet(
			prevMinimumStaking, 
			_newMinimumStaking, 
			block.timestamp
		);
    }

    /**
     * @dev Internal: Set the master copy to use as clones for the curation token.
     * @param _newBardsShareTokenImpl Address of implementation contract to use for curation staking tokens
     */
    function _setBardsShareTokenImpl(address _newBardsShareTokenImpl) private {
        require(_newBardsShareTokenImpl != address(0), "Token master must be non-empty");
        require(Address.isContract(_newBardsShareTokenImpl), "Token master must be a contract");

		address prevBardsShareTokenImpl = bardsShareTokenImpl;
        bardsShareTokenImpl = _newBardsShareTokenImpl;
        emit Events.CurationStakingTokenMasterSet(
			prevBardsShareTokenImpl,
			_newBardsShareTokenImpl,
			block.timestamp
		);
    }

    /**
     * @notice Internal: Set the thawing period for unstaking.
     * 
     * @param _newThawingPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function _setThawingPeriod(uint32 _newThawingPeriod) private {
        require(_newThawingPeriod > 0, "!thawingPeriod");
        uint32 prevThawingPeriod = thawingPeriod;
        thawingPeriod = _newThawingPeriod;
        emit Events.ThawingPeriodSet(
            prevThawingPeriod, 
            _newThawingPeriod, 
            block.timestamp
        );
    }

    /**
     * @notice Internal: Set the period in epochs that need to pass before fees in rebate pool can be claimed.
     * 
     * @param _newChannelDisputeEpochs Period in epochs
     */
    function _setChannelDisputeEpochs(uint32 _newChannelDisputeEpochs) private {
        require(_newChannelDisputeEpochs > 0, "!channelDisputeEpochs");
        uint32 prevChannelDisputeEpochs = channelDisputeEpochs;
        channelDisputeEpochs = _newChannelDisputeEpochs;
        emit Events.ChannelDisputeEpochsSet(
            prevChannelDisputeEpochs,
            _newChannelDisputeEpochs,
            block.timestamp
        );
    }

    /**
     * @notice Internal: Set the max time allowed for stake on allocations.
     * 
     * @param _newMaxAllocationEpochs Allocation duration limit in epochs
     */
    function _setMaxAllocationEpochs(uint32 _newMaxAllocationEpochs) private {
        require(_newMaxAllocationEpochs > 0, "!maxAllocationEpochs");
        uint32 prevMaxAllocationEpochs = maxAllocationEpochs;
        maxAllocationEpochs = _newMaxAllocationEpochs;
        emit Events.ChannelDisputeEpochsSet(
            prevMaxAllocationEpochs,
            _newMaxAllocationEpochs,
            block.timestamp
        );
    }

    /**
     * @dev Set the rebate ratio (fees to allocated stake).
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function _setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) private {
        require(_alphaNumerator > 0 && _alphaDenominator > 0, "!alpha");
        alphaNumerator = _alphaNumerator;
        alphaDenominator = _alphaDenominator;
        emit Events.RebateRatioSet(
            alphaNumerator, 
            alphaDenominator, 
            block.timestamp
        );
    }

    /**
     * @notice Triggers an update of rewards due to a change in share.
     * 
     * @param _curationId Curation Id
     */
    function _updateRewardsWithStaking(uint256 _curationId) private returns (uint256) {
        IRewardsManager rewardsManager = rewardsManager();
        if (address(rewardsManager) != address(0)) {
            return rewardsManager.onCurationStakingUpdate(_curationId);
        }
        return 0;
    }

    /**
     * @notice Triggers an update of rewards due to a change in allocations
     * 
     * @param _curationId Curation Id
     */
    function _updateRewardsWithAllocation(uint256 _curationId) 
        private 
        returns (uint256) 
    {
        IRewardsManager rewardsManager = rewardsManager();
        if (address(rewardsManager) != address(0)) {
            return rewardsManager.onCurationAllocationUpdate(_curationId);
        }
        return 0;
    }

    /**
     * @dev Check if the caller is authorized
     */
    function _isAuth(address _theBards) private view returns (bool) {
        return msg.sender == _theBards || isOperator(msg.sender, _theBards) == true;
    }

    /**
     * @notice Allocate available tokens to a curation.
     * 
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function _allocate(
        DataTypes.CreateAllocateData calldata _createAllocationData 
    ) private {
        // Check allocation
        require(
            _createAllocationData.allocationID != address(0), 
            "!alloc"
        );
        require(
            _getAllocationState(_createAllocationData.allocationID) == DataTypes.AllocationState.Null, 
            "!null"
        );

        // // Caller must prove that they own the private key for the allocationID adddress
        // // The proof is an Ethereum signed message of KECCAK256(indexerAddress,allocationID)
        // bytes32 messageHash = keccak256(abi.encodePacked(_indexer, _allocationID));
        // bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
        // require(ECDSA.recover(digest, _proof) == _allocationID, "!proof");


        // Allocating zero-tokens still needs to comply with stake requirements
        require(
            _stakingPools[_createAllocationData.curationId].tokens[address(bardsCurationToken())] >= minimumStake,
            "!minimumStake"
        );

        // Creates an allocation
        // Allocation identifiers are not reused
        // The assetHolder address can send collected funds to the allocation
        Allocation memory alloc = Allocation(
            _createAllocationData.curationId,
            _createAllocationData.recipientsMeta,
            _createAllocationData.tokens, // Tokens allocated
            epochManager().currentEpoch(), // createdAtEpoch
            0, // closedAtEpoch
            [], // Initialize currencies
            [], // Initialize collected fees
            0, // Initialize effective allocation
            (_createAllocationData.tokens > 0) ? _updateRewardsWithAllocation(_createAllocationData.curationId) : 0 // Initialize accumulated rewards per stake allocated
        );
        allocations[_createAllocationData.allocationID] = alloc;

        // -- Rewards Distribution --
        // Process non-zero-allocation rewards tracking
        if (_createAllocationData.tokens > 0) {
            // Mark allocated tokens as used
            _stakingPools[_createAllocationData.curationId].tokensAllocated.add(alloc.tokens);
        }

        emit Events.AllocationCreated(
            alloc.curationId,
            alloc.createdAtEpoch,
            alloc.tokens,
            alloc.allocationID,
            alloc.recipientsMeta,
            block.timestamp
        );
    }

    /**
     * @dev Close an allocation and free the staked tokens.
     * @param _allocationID The allocation identifier
     */
    function _closeAllocation(address _allocationID) private {
        // Allocation must exist and be active
        DataTypes.AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState == DataTypes.AllocationState.Active, "!active");

        // Get allocation
        DataTypes.Allocation memory alloc = allocations[_allocationID];

        // Validate that an allocation cannot be closed before one epoch
        alloc.closedAtEpoch = epochManager().currentEpoch();
        uint256 epochs = MathUtils.diffOrZero(alloc.closedAtEpoch, alloc.createdAtEpoch);
        require(epochs > 0, "<epochs");

        // Close the allocation and start counting a period to settle remaining payments from hub
        allocations[_allocationID].closedAtEpoch = alloc.closedAtEpoch;

        // -- Rebate Pool --

        // Calculate effective allocation for the amount of epochs it remained allocated
        alloc.effectiveAllocationStake = _getEffectiveAllocation(
            maxAllocationEpochs,
            alloc.tokens,
            epochs
        );
        allocations[_allocationID].effectiveAllocationStake = alloc.effectiveAllocationStake;

        // Account collected fees and effective allocation in rebate pool for the epoch
        Rebates.Pool storage rebatePool = rebates[alloc.closedAtEpoch];
        if (!rebatePool.exists()) {
            rebatePool.init(alphaNumerator, alphaDenominator);
        }
        for(uint256 i=0; i < alloc.currencies; i++){
            rebatePool.addToPool(alloc.currencies[i], alloc.collectedFees[i], alloc.effectiveAllocationStake);
        }

        // -- Rewards Distribution --

        // Process non-zero-allocation rewards tracking
        if (alloc.tokens > 0) {
            // Distribute rewards
            _distributeRewards(alloc.allocationID);
            // Free allocated tokens from use
            _stakingPools[alloc.curationId].tokensAllocated.sub(alloc.tokens);
        }

        emit Events.AllocationClosed(
            alloc.curationId,
            alloc.closedAtEpoch,
            alloc.tokens,
            alloc.allocationID,
            alloc.effectiveAllocationStake,
            block.timestamp
        );
    }

    /**
     * @dev Claim tokens from the rebate pool.
     * @param _allocationID Allocation from where we are claiming tokens
     * @param _restake True if restake fees instead of transfer to indexer
     */
    function _claim(address _allocationID, bool _restake) private {
        // Funds can only be claimed after a period of time passed since allocation was closed
        DataTypes.AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState == DataTypes.AllocationState.Finalized, "!finalized");

        // Get allocation
        DataTypes.Allocation memory alloc = allocations[_allocationID];

        (   
            address[] sellers,
            address[] sellerFundsRecipients,
            uint32[] sellerBpses,
            uint32 stakingBps,
        ) = abi.decode(
            alloc.recipientsMeta, 
            (address[], address[], uint32[], uint32)
        );

        // Process rebate reward
        DataTypes.RebatePool storage rebatePool = rebates[alloc.closedAtEpoch];
        uint256 tokensToClaim;
        uint256 delegationRewards;
        address curCurrency;
        uint256 _reward;
        IBardsCurationToken bct = bardsCurationToken();

        for(uint256 i=0; i < alloc.currencies.length; i++){
            curCurrency = alloc.currencies[i];
            tokensToClaim = rebatePool.redeem(curCurrency, alloc.collectedFees[curCurrency], alloc.effectiveAllocationStake);
            // Add delegation rewards to the delegation pool
            delegationRewards = _collectDelegationRewards(alloc.curationId, curCurrency, tokensToClaim, stakingBps);
            tokensToClaim = tokensToClaim.sub(delegationRewards);

            // When there are tokens to claim from the rebate pool, transfer or restake
            // Send the split rewards
            for(uint256 i = 0; i < sellers.length; i++){
                _reward = uint256(sellerBpses[i]).mul(remainingRewards).div(Constants.MAX_BPS);
                _sendRewards(
                    IERC20(curCurrency),
                    _reward,
                    sellerFundsRecipients[i]
                );
            }

            emit Events.RebateClaimed(
                alloc.curationId,
                _allocationID,
                curCurrency,
                epochManager().currentEpoch(),
                alloc.closedAtEpoch,
                tokensToClaim,
                rebatePool.unclaimedAllocationsCount,
                delegationRewards,
                block.timestamp
            );
        }
        
        // Purge allocation data
        mapping (address => uint256) _tmp;
        allocations[_allocationID].recipientsMeta = bytes(0);
        allocations[_allocationID].tokens = 0;
        allocations[_allocationID].createdAtEpoch = 0; // This avoid collect(), close() and claim() to be called
        allocations[_allocationID].closedAtEpoch = 0;
        allocations[_allocationID].currencies = [];
        allocations[_allocationID].collectedFees = _tmp;
        allocations[_allocationID].effectiveAllocationStake = 0;
        allocations[_allocationID].accRewardsPerAllocatedToken = 0;

        // -- Interactions --
        // When all allocations processed then burn unclaimed fees and prune rebate pool
        if (rebatePool.unclaimedAllocationsCount == 0) {
            TokenUtils.burnTokens(bct, rebatePool.unclaimedFees(address(bardsCurationToken)));
            delete rebates[alloc.closedAtEpoch];
        }
    }

    /**
     * @notice Return the current state of an allocation
     * 
     * @param _allocationID Allocation identifier
     * @return AllocationState
     */
    function _getAllocationState(address _allocationID) 
        private 
        view 
        returns (DataTypes.AllocationState) 
    {
        DataTypes.Allocation storage alloc = allocations[_allocationID];

        if (alloc.curationId == 0) {
            return DataTypes.AllocationState.Null;
        }
        if (alloc.createdAtEpoch == 0) {
            return DataTypes.AllocationState.Claimed;
        }

        uint256 closedAtEpoch = alloc.closedAtEpoch;
        if (closedAtEpoch == 0) {
            return DataTypes.AllocationState.Active;
        }

        uint256 epochs = epochManager().epochsSince(closedAtEpoch);
        if (epochs >= channelDisputeEpochs) {
            return DataTypes.AllocationState.Finalized;
        }
        return DataTypes.AllocationState.Closed;
    }

    /**
     * @notice Get the effective stake allocation considering epochs from allocation to closing.
     * 
     * @param _tokens Amount of tokens allocated
     * @param _numEpochs Number of epochs that passed from allocation to closing
     * @return Effective allocated tokens across epochs
     */
    function _getEffectiveAllocation(
        uint256 _tokens,
        uint256 _numEpochs
    ) private pure returns (uint256) {
        bool shouldCap = maxAllocationEpochs > 0 && _numEpochs > maxAllocationEpochs;
        return _tokens.mul((shouldCap) ? maxAllocationEpochs : _numEpochs);
    }

    /**
     * @notice Assign rewards for the closed allocation to creators and delegators.
     * TODO support re-stake
     * 
     * @param _allocationID Allocation
     */
    function _distributeRewards(address _allocationID) private {
        IRewardsManager rewardsManager = rewardsManager();
        if (address(rewardsManager) == address(0)) {
            return;
        }

        // Automatically triggers update of rewards snapshot as allocation will change
        // after this call. Take rewards mint tokens for the Staking contract to distribute
        // between indexer and delegators
        uint256 totalRewards = rewardsManager.takeRewards(_allocationID);
        if (totalRewards == 0) {
            return;
        }

        (   
            address[] sellers,
            address[] sellerFundsRecipients,
            uint32[] sellerBpses,
            uint32 stakingBps,
        ) = abi.decode(
            allocations[_allocationID].recipientsMeta, 
            (address[], address[], uint32[], uint32)
        );

        IBardsCurationToken bct = bardsCurationToken();

        // Calculate delegation rewards and add them to the delegation pool
        uint256 delegationRewards = _collectDelegationRewards(allocations[_allocationID].curationId, address(bct), totalRewards, stakingBps);
        uint256 remainingRewards = totalRewards.sub(delegationRewards);

        // Send the split rewards
        uint256 _reward;
        for(uint256 i = 0; i < sellers.length; i++){
            _reward = uint256(sellerBpses[i]).mul(remainingRewards).div(Constants.MAX_BPS);
            _sendRewards(
                bct,
                _reward,
                sellerFundsRecipients[i]
            );
        }
        
    }

    /**
     * @notice Collect the delegation rewards.
     * This function will assign the collected fees to the delegation pool.
     * @param _curationId Curation to which the tokens to distribute are related
     * @param _currency The currency of token.
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     * @param _rewardCut The reward cut percent for delegation.
     * @return Amount of delegation rewards
     */
    function _collectDelegationRewards(uint256 _curationId, address _currency, uint256 _tokens, uint32 _rewardCut)
        private
        returns (uint256)
    {
        uint256 delegationRewards = 0;
        DataTypes.CurationStakingPool storage stakingPool = _stakingPool[_curationId];
        
        if (stakingPool.tokens[_currency] > 0 && _rewardCut < Constants.MAX_BPS) {
            uint256 delegationRewards = uint256(_rewardCut).mul(_tokens).div(Constants.MAX_BPS);
            stakingPool.tokens[_currency] = stakingPool.tokens[_currency].add(delegationRewards);
        }
        return delegationRewards;
    }

    /**
     * @dev Send rewards to the appropiate destination.
     * @param _graphToken Graph token
     * @param _amount Number of rewards tokens
     * @param _beneficiary Address of the beneficiary of rewards
     */
    function _sendRewards(
        IBardsCurationToken _bardsCurationToken,
        uint256 _amount,
        address _beneficiary,
    ) private {
        if (_amount == 0) return;

        // Transfer funds to the beneficiary
        TokenUtils.pushTokens(
            _bardsCurationToken,
            _beneficiary
            _amount
        );
    }

}