// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/tokens/IBardsStaking.sol';
import '../common/Multicall.sol';
import '../storages/BardsStakingStorage.sol';
import './BardsShareToken.sol';
import './BardsCurationToken.sol';
import '../../utils/DataTypes.sol';
import '../../utils/Errors.sol';
import '../../utils/Events.sol';
import '../../utils/Constants.sol';
import '../../utils/BancorFormula.sol';
import '../../utils/Rebates.sol';
import '../../utils/MultiCurrencyFeesUtils.sol';
import '../../utils/TokenUtils.sol';
import '../../utils/MathUtils.sol';
import '../../interfaces/tokens/IBardsShareToken.sol';
import '../../interfaces/tokens/IBardsCurationToken.sol';
import '../govs/ContractRegistrar.sol';
import '../govs/BardsPausable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Curation contract
 * 
 * @author TheBards Protocol
 * 
 * @notice Allows delegator to delegate to curations by staking Bards Curation Tokens (BCT). 
 * Additionally, delegator will earn a share of all the curation share revenue that the curation generates.
 * A delegator deposit goes to a curation staking pool along with the deposits of other delegators,
 * only one such pool exists for each curation.
 * The contract mints Bards Curation Shares (BCS) according to a bonding curve for each individual
 * curation staking pool where BCT is deposited.
 * Holders can burn BCS using this contract to get BCT tokens back according to the
 * bonding curve.
 */
contract BardsStaking is
    IBardsStaking, 
    BardsStakingStorage,
    ContractRegistrar, 
    BardsPausable,
    Multicall
{
	using SafeMath for uint256;
    using Rebates for DataTypes.RebatePool;
    using MultiCurrencyFeesUtils for DataTypes.MultiCurrencyFees;
	
	/**
     * @dev Initialize this contract.
     */
    function initialize(
		address _HUB,
        address _bondingCurve,
        address _bardsShareTokenImpl,
        uint32 _defaultStakingReserveRatio,
        uint32 _stakingTaxPercentage,
        uint256 _minimumCurationStaking,
        address _stakingAddress
    ) 
        external 
    {
		if (_HUB == address(0)) revert Errors.InitParamsInvalid();
        require(_bondingCurve != address(0), "Bonding curve must be set");
        bondingCurve = _bondingCurve;
		ContractRegistrar._initialize(_HUB);
        // Settings
		_setBardsShareTokenImpl(_bardsShareTokenImpl);
        _setDefaultReserveRatio(_defaultStakingReserveRatio);
        _setStakingTaxPercentage(_stakingTaxPercentage);
        _setMinimumStaking(_minimumCurationStaking);
        _setStakingAddress(_stakingAddress);
    }

    /// @inheritdoc IBardsStaking
    function setStakingAddress(address _stakingAddress)
        external
        override
        onlyHub 
    {
        _setStakingAddress(_stakingAddress);
    }

    /// @inheritdoc IBardsStaking
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) 
		external 
		override 
	    onlyHub 
    {
        _setDefaultReserveRatio(_defaultReserveRatio);
    }

    /// @inheritdoc IBardsStaking
    function setMinimumStaking(uint256 _minimumStaking)
        external
        override
        onlyHub
    {
        _setMinimumStaking(_minimumStaking);
    }

    /// @inheritdoc IBardsStaking
    function setThawingPeriod(uint32 _thawingPeriod)
        external
        override
        onlyHub
    {
        _setThawingPeriod(_thawingPeriod);
    }

    /// @inheritdoc IBardsStaking
    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) 
        external 
        override 
        onlyHub 
    {
        _setChannelDisputeEpochs(_channelDisputeEpochs);
    }

    /// @inheritdoc IBardsStaking
    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) 
        external 
        override 
        onlyHub 
    {
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
        onlyHub 
    {
        _setRebateRatio(_alphaNumerator, _alphaDenominator);
    }

    /// @inheritdoc IBardsStaking
	function setStakingTaxPercentage(uint32 _percentage) 
		external 
		override 
	    onlyHub 
    {
        _setStakingTaxPercentage(_percentage);
    }

    /// @inheritdoc IBardsStaking
    function setBardsShareTokenImpl(address _bardsShareTokenImpl) 
		external 
		override 
	    onlyHub 
    {
        _setBardsShareTokenImpl(_bardsShareTokenImpl);
    }

    /// @inheritdoc IBardsStaking
    function setOperator(
        address _operator, 
        bool _allowed
    ) 
        external 
        override 
    {
        require(_operator != msg.sender, "operator == sender");
        operatorAuth[msg.sender][_operator] = _allowed;
        emit Events.OperatorSet(
            msg.sender, 
            _operator, 
            _allowed, 
            block.timestamp
        );
    }

    /// @inheritdoc IBardsStaking
    function isDelegator(
        uint256 _curationId, 
        address _delegator
    ) 
        public 
        view 
        override 
        returns (bool)
    {
        return _stakingPools[_curationId].delegators[_delegator].shares > 0;
    }

    /// @inheritdoc IBardsStaking
    function isSeller(
        address _allocationID,
        address _seller
    ) 
        public 
        view 
        override 
        returns (bool)
    {
        DataTypes.Allocation storage _alloc = allocations[_allocationID];
        (   
            address[] memory sellers,
            ,
            uint32[] memory sellerBpses,
        ) = abi.decode(
            _alloc.recipientsMeta,
            (address[], address[], uint32[], uint32)
        );
        for(uint256 i = 0; i < sellers.length; i ++){
            if (sellers[i] == _seller && sellerBpses[i] > 0){
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IBardsStaking
    function isOperator(address _curator, address _operator) 
        public 
        view 
        override 
        returns (bool) 
    {
        return operatorAuth[_curator][_operator];
    }

    /// @inheritdoc IBardsStaking
	function stake(
        uint256 _curationId,
        uint256 _tokens
    ) 
        external 
        override 
        returns (uint256, uint256) 
    {
        address delegator = msg.sender;
        TokenUtils.transfer(bardsCurationToken(), delegator, _tokens, stakingAddress);

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
        internal
        returns (uint256, uint256) 
    {
        // Need to deposit some funds
        require(_tokens > 0, "Cannot deposit zero tokens");

        // Exchange BCT tokens for BST of the curation staking pool
        (uint256 shareOut, uint256 stakingTax) = tokensToShare(_curationId, _tokens);

        // Slippage protection
        // require(shareOut >= _shareOutMin, "Slippage protection");

        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];

        // If it hasn't been staked before then initialize the curve
        if (!isStaked(_curationId)) {
            stakingPool.reserveRatio = defaultStakingReserveRatio;

            // If no share token for the pool - create one
            if (stakingPool.bst == address(0)) {
                // Use a minimal proxy to reduce gas cost
                IBardsShareToken bst = IBardsShareToken(Clones.clone(bardsShareTokenImpl));
                bst.initialize();
                stakingPool.bst = address(bst);
            }
        }

        // Trigger update rewards calculation snapshot
        _updateRewardsWithStaking(_curationId);

        // Transfer tokens from the delegator to this contract
        // Burn the staking tax
        // NOTE: This needs to happen after _updateRewards snapshot as that function
        // is using balanceOf(stakingAddress)
        IBardsCurationToken _bardsCurationToken = bardsCurationToken();
        TokenUtils.burnTokens(_bardsCurationToken, stakingTax);

        uint256 remainingTokens = _tokens.sub(stakingTax);

        // Update curation staking pool
        stakingPool.tokens = stakingPool.tokens.add(remainingTokens);
        totalStakingTokens = totalStakingTokens.add(remainingTokens);

        IBardsShareToken(stakingPool.bst).mint(_delegator, shareOut);
        // Update the individual delegation
        DataTypes.Delegation storage delegation = stakingPool.delegators[_delegator];
        delegation.shares = delegation.shares.add(shareOut);

        // reset the current epoch totalShare of MultiCurrencyFees.
        stakingPool.fees[epochManager().currentEpoch()].totalShare = getStakingPoolShare(_curationId);

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
        uint256 _shares
    ) 
        external 
        override 
        returns (uint256)
    {
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
    ) 
        private 
        returns (uint256) 
    {
        // Validations
        require(_shares > 0, "Cannot burn zero share");
        require(
            getDelegatorShare(_delegator, _curationId) >= _shares,
            "Cannot burn more share than you own"
        );
        // Get the amount of tokens to refund based on returned signal
        uint256 tokensOut = shareToTokens(_curationId, _shares);

        // Trigger update rewards calculation
        _updateRewardsWithStaking(_curationId);

        // Update curation pool
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        // Update the individual delegation
        DataTypes.Delegation storage delegation = stakingPool.delegators[_delegator];

        // Withdraw tokens if available
        if (getWithdraweableBCTTokens(_curationId, _delegator) > 0) {
            _withdrawStaked(_delegator, _curationId, 0);
        }

        uint256 currentEpoch = epochManager().currentEpoch();
        // Withdraw fees of available currencies between lastWithdrawFeesEpoch and currentEpoch, which excluding currentEpoch.
        _withdrawFees(
            _curationId,
            _shares,
            delegation.lastWithdrawFeesEpoch, 
            currentEpoch, 
            _delegator
        );

        // burn share
        IBardsShareToken(stakingPool.bst).burnFrom(_delegator, _shares);
        // update the delegation
        delegation.shares = delegation.shares.sub(_shares);
        delegation.tokensLockedUntil = currentEpoch.add(thawingPeriod);
        delegation.lastWithdrawFeesEpoch = currentEpoch;

        // reset the current epoch totalShare of MultiCurrencyFees.
        stakingPool.fees[currentEpoch].totalShare = getStakingPoolShare(_curationId);

        emit Events.StakeDelegatedLocked(
            _curationId, 
            _delegator, 
            _shares, 
            delegation.tokensLockedUntil, 
            block.timestamp
        );

        return tokensOut;
    }

    /**
     * @notice Withdraw fees from start epoch to end epoch from staking pool.
     */
    function _withdrawFees(
        uint256 _curationId,
        uint256 _shares,
        uint256 _startEpoch,
        uint256 _endEpoch,
        address _delegator
    )
        internal
    {
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        uint256 _curFee;
        // Collect fees from startEpoch to endEpoch
        for(uint256 _epoch = _startEpoch; _epoch < _endEpoch; _epoch++){
            DataTypes.MultiCurrencyFees storage _curFees = stakingPool.fees[_epoch];
            for(uint256 i= 0; i < _curFees.currencies.length; i++){
                address _currency = _curFees.currencies[i];
                if (_curFees.fees[_currency] == 0){
                    delete _curFees.fees[_currency];
                    continue;
                }
                _curFee = _shareToFees(_curationId, _shares, _currency, _epoch);
                if (_curFee <= 0){
                    continue;
                }
                _curFee = MathUtils.min(_curFee, _curFees.fees[_currency]);
                // collect fees using a tmp pool of 0 epoch
                stakingPool.fees[0].tryInsertCurrencyFees(_currency, _curFee);
                _curFees.fees[_currency] = _curFees.fees[_currency].sub(_curFee);
            }
        }

        // Withdraw Fees, clear tmp pool
        stakingPool.fees[0].withdraw(stakingAddress, _delegator);
        stakingPool.fees[0].clear();

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
    function closeAllocation(address _allocationID, uint256 _stakeToCuration) 
        external 
        override 
        whenNotPaused 
    {
        _closeAllocation(_allocationID, _stakeToCuration);
    }

    /// @inheritdoc IBardsStaking
    function closeAllocationMany(address[] calldata _allocationIDs, uint256[] calldata _stakeToCurations)
        external
        override
        whenNotPaused 
    {
        require(_allocationIDs.length == _stakeToCurations.length, 'length not match');

        for (uint256 i = 0; i < _allocationIDs.length; i++) {
            _closeAllocation(_allocationIDs[i], _stakeToCurations[i]);
        }
    }

    /// @inheritdoc IBardsStaking
    function closeAndAllocate(
        address _closingAllocationID,
        uint256 _stakeToCuration,
        DataTypes.CreateAllocateData calldata _createAllocationData
    ) 
        external 
        override 
        whenNotPaused 
    {
        _closeAllocation(_closingAllocationID, _stakeToCuration);
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
        uint256 tradeFees = _tokens;

        // Process trade fees only if non-zero amount
        if (tradeFees > 0) {
            // Add funds to the allocation
            alloc.collectedFees.tryInsertCurrencyFees(_currency, tradeFees);

            // When allocation is closed redirect funds to the rebate pool
            // This way we can keep collecting tokens even after the allocation is closed and
            // before it gets to the finalized state.
            if (allocState == DataTypes.AllocationState.Closed) {
                DataTypes.RebatePool storage rebatePool = rebates[alloc.closedAtEpoch];
                rebatePool.fees.tryInsertCurrencyFees(_currency, tradeFees);
            }
        }

        emit Events.AllocationCollected(
            alloc.curationId,
            epochManager().currentEpoch(),
            _tokens,
            _allocationID,
            msg.sender,
            _currency,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsStaking
    function collectStakingFees(
        uint256 _curationId, 
        address _currency, 
        uint256 _tokens
    )
        external 
        override
    {
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        
        if (_currency == address(bardsCurationToken())){
            stakingPool.tokens = stakingPool.tokens.add(_tokens);
        }else{
            uint256 _currentEpoch = epochManager().currentEpoch();
            stakingPool.fees[_currentEpoch].fees[_currency] = stakingPool.fees[_currentEpoch].fees[_currency].add(_tokens);
        }
    }

    /// @inheritdoc IBardsStaking
    function claim(
        address _allocationID, 
        uint256 _stakeToCuration
    ) 
        external 
        override 
        whenNotPaused 
    {
        _claim(_allocationID, _stakeToCuration);
    }

    /// @inheritdoc IBardsStaking
    function claimMany(
        address[] calldata _allocationIDs, 
        uint256 _stakeToCuration
    )
        external
        override
        whenNotPaused
    {
        for (uint256 i = 0; i < _allocationIDs.length; i++) {
            _claim(_allocationIDs[i], _stakeToCuration);
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
            return _delegation.tokensLocked;
        }
        return 0;
    }

    /// @inheritdoc IBardsStaking
    function getCurationAllocatedTokens(uint256 _curationId)
        external
        view
        override
        returns (uint256)
    {
        return _stakingPools[_curationId].tokens;
    }

    /// @inheritdoc IBardsStaking
    function isStaked(uint256 _curationId) 
		public 
		view 
		override 
	    returns (bool) 
    {
        return _stakingPools[_curationId].tokens > 0;
    }

    /// @inheritdoc IBardsStaking
    function isAllocation(address _allocationID) external view override returns (bool) {
        return _getAllocationState(_allocationID) != DataTypes.AllocationState.Null;
    }

    /// @inheritdoc IBardsStaking
    function getAllocationState(address _allocationID)
        external
        view
        override
        returns (DataTypes.AllocationState)
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
        uint256 shareOut = _tokensToShare(_curationId, _tokens.sub(stakingTax));
        return (shareOut, stakingTax);
    }

    /// @inheritdoc IBardsStaking
    function withdrawStaked(
        uint256 _curationId,
        uint256 _stakeToCuration
    ) 
        public
        override
        returns (uint256)
    {
        return _withdrawStaked(msg.sender, _curationId, _stakeToCuration);
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
    ) 
        private 
        returns (uint256) 
    {
        // Get the delegation pool of the indexer
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        DataTypes.Delegation storage delegation = stakingPool.delegators[_delegator];

        // Validation
        uint256 tokensToWithdraw = getWithdraweableBCTTokens(_curationId, _delegator);
        require(tokensToWithdraw > 0, "!tokens");

        // Reset lock
        delegation.tokensLocked = 0;
        delegation.tokensLockedUntil = 0;

        if (_stakeToCuration != 0) {
            // Re-delegate tokens to a new curation
            _stake(_stakeToCuration, tokensToWithdraw, _delegator);
        }else {
            // Return tokens to the delegator
            TokenUtils.transfer(
                bardsCurationToken(), 
                stakingAddress , 
                delegation.tokensLocked, 
                _delegator
            );
        }

        emit Events.StakeDelegatedWithdrawn(
            _curationId, 
            _delegator, 
            tokensToWithdraw, 
            block.timestamp
        );
        
        return tokensToWithdraw;
    }

    /**
     * @dev Calculate amount of signal that can be bought with tokens in a curation staking pool.
     * @param _curationId Curation to mint share
     * @param _tokens Amount of tokens used to mint share
     * @return Amount of share that can be bought with tokens
     */
    function _tokensToShare(
        uint256 _curationId, 
        uint256 _tokens
    )
        private
        view
        returns (uint256)
    {
        // Get curation pool
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];

        // Init curation pool
        if (stakingPool.tokens == 0) {
            require(
                _tokens >= minimumStaking,
                "Curation staking is below minimum required"
            );
            return
                BancorFormula(bondingCurve)
                    .calculatePurchaseReturn(
                        Constants.SHARE_PER_MINIMUM_DEPOSIT,
                        minimumStaking,
                        defaultStakingReserveRatio,
                        _tokens.sub(minimumStaking)
                    )
                    .add(Constants.SHARE_PER_MINIMUM_DEPOSIT);
        }

        return
            BancorFormula(bondingCurve)
                .calculatePurchaseReturn(
                    getStakingPoolShare(_curationId),
                    stakingPool.tokens,
                    stakingPool.reserveRatio,
                    _tokens
            );
    }

    /// @inheritdoc IBardsStaking
    function shareToTokens(
        uint256 _curationId, 
        uint256 _shares
    )
        public
        view
        override
        returns (uint256)
    {
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        uint256 stakingPoolShare = getStakingPoolShare(_curationId);

        require(
            stakingPool.tokens > 0,
            "Curation must be built to perform calculations"
        );
        require(
            stakingPoolShare >= _shares,
            "Share must be above or equal to signal issued in the curation staking pool"
        );

        return
            BancorFormula(bondingCurve).calculateSaleReturn(
                stakingPoolShare,
                stakingPool.tokens,
                stakingPool.reserveRatio,
                _shares
            );
    }

    /**
     * @notice Calculate number of fees to get when withdraw from a staking pool.
     */
    function _shareToFees(
        uint256 _curationId, 
        uint256 _shares,
        address _currency,
        uint256 _epoch
    )
        internal
        view
        returns (uint256)
    {
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        uint256 stakingPoolShare = stakingPool.fees[_epoch].totalShare;

        require(
            stakingPool.tokens > 0,
            "Curation must be built to perform calculations"
        );
        require(
            stakingPoolShare >= _shares,
            "Share must be above or equal to signal issued in the curation staking pool"
        );

        return
            BancorFormula(bondingCurve).calculateSaleReturn(
                stakingPoolShare,
                stakingPool.fees[_epoch].fees[_currency],
                stakingPool.reserveRatio,
                _shares
            );
    }

    /// @inheritdoc IBardsStaking
    function getStakingAddress()
        public
        view
        override
        returns (address)
    {
        return stakingAddress;
    }

    /// @inheritdoc IBardsStaking
    function getTotalStakingToken()
        public
        view
        override
        returns (uint256)
    {
        return totalStakingTokens;
    }

    /**
     * @dev Return the simple allocation by ID.
     * @param _allocationID Address used as allocation identifier
     * @return SimpleAllocation data
     */
    function getSimpleAllocation(address _allocationID)
        external
        view
        override
        returns (DataTypes.SimpleAllocation memory)
    {
        DataTypes.Allocation storage alloc = allocations[_allocationID];
        return DataTypes.SimpleAllocation(
            alloc.curator,
            alloc.curationId,
            alloc.recipientsMeta,
            alloc.tokens,
            alloc.createdAtEpoch,
            alloc.closedAtEpoch,
            alloc.effectiveAllocationStake,
            alloc.accRewardsPerAllocatedToken
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
    function getStakingPoolToken(
        uint256 _curationId
    )
        external
        view
        override
        returns (uint256)
    {
        return _stakingPools[_curationId].tokens;
    }

	/**
     * @notice Internal: Set the staking tax percentage to charge when a delegator deposits BCT tokens.
     * 
     * @param _newPercentage Staking tax percentage charged when depositing BCT tokens
     */
    function _setStakingTaxPercentage(uint32 _newPercentage) 
        private 
    {
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
     * @notice Internal: Set the address of staking tokens.
     * 
     * @param _newStakingAddress The address of staking tokens.
     */
    function _setStakingAddress(
		address _newStakingAddress
	) 
        private 
    {
        // Reserve Ratio must be within 0% to 100% (inclusive, in PPM)
        require(_newStakingAddress != address(0), "staking address must not be address(0)");

		address prevStakingAddress = stakingAddress;
        stakingAddress = _newStakingAddress;
        emit Events.StakingAddressSet(
			prevStakingAddress, 
			_newStakingAddress, 
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
	) 
        private 
    {
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
	) 
        private 
    {
        require(_newMinimumStaking > 0, "Minimum curation deposit cannot be 0");

		uint256 prevMinimumStaking = minimumStaking;	
        minimumStaking = _newMinimumStaking;

        emit Events.MinimumStakingSet(
			prevMinimumStaking, 
			_newMinimumStaking, 
			block.timestamp
		);
    }

    /**
     * @dev Internal: Set the master copy to use as clones for the curation token.
     * @param _newBardsShareTokenImpl Address of implementation contract to use for curation staking tokens
     */
    function _setBardsShareTokenImpl(address _newBardsShareTokenImpl) 
        private 
    {
        require(_newBardsShareTokenImpl != address(0), "Token master must be non-empty");
        require(Address.isContract(_newBardsShareTokenImpl), "Token master must be a contract");

		address prevBardsShareTokenImpl = bardsShareTokenImpl;
        bardsShareTokenImpl = _newBardsShareTokenImpl;
        emit Events.BardsShareTokenImplSet(
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
    function _setThawingPeriod(uint32 _newThawingPeriod) 
        private 
    {
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
    function _setChannelDisputeEpochs(uint32 _newChannelDisputeEpochs) 
        private 
    {
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
    function _setMaxAllocationEpochs(uint32 _newMaxAllocationEpochs) 
        private 
    {
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
    function _setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) 
        private 
    {
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
    function _updateRewardsWithStaking(uint256 _curationId) 
        private 
        returns (uint256) 
    {
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
    function _isAuth(address _curator) 
        private 
        view 
        returns (bool) 
    {
        return msg.sender == _curator || isOperator(_curator, msg.sender) == true;
    }

    /**
     * @notice Caller must prove that they own the private key for the allocationID adddress
     * The proof is an Ethereum signed message of KECCAK256(indexerAddress,allocationID)
     * 
     * @param curator The Address of curator
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function _proveAllocation(
        address curator,
        DataTypes.CreateAllocateData calldata _createAllocationData
    )
        private
        pure
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(curator, _createAllocationData.allocationID));
        bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
        return ECDSA.recover(digest, _createAllocationData.proof) == _createAllocationData.allocationID;
    }

    /**
     * @notice Allocate available tokens to a curation.
     * 
     * @param curator The Address of curator
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function _allocate(
        address curator,
        DataTypes.CreateAllocateData calldata _createAllocationData 
    ) 
        private 
    {
        // Check allocation
        require(
            _createAllocationData.allocationID != address(0), 
            "!alloc"
        );
        require(
            _getAllocationState(_createAllocationData.allocationID) == DataTypes.AllocationState.Null, 
            "!null"
        );

        // Caller must prove that they own the private key for the allocationID adddress
        require(_proveAllocation(curator, _createAllocationData), "!proof");

        // Allocating zero-tokens still needs to comply with stake requirements
        require(
            _stakingPools[_createAllocationData.curationId].tokens >= minimumStaking,
            "!minimumStaking"
        );

        // Creates an allocation
        // Allocation identifiers are not reused
        allocations[_createAllocationData.allocationID].curationId = _createAllocationData.curationId;
        allocations[_createAllocationData.allocationID].recipientsMeta = _createAllocationData.recipientsMeta;
        allocations[_createAllocationData.allocationID].tokens = _createAllocationData.tokens;
        allocations[_createAllocationData.allocationID].createdAtEpoch = epochManager().currentEpoch();
        allocations[_createAllocationData.allocationID].closedAtEpoch = 0;
        // Initialize effective allocation
        allocations[_createAllocationData.allocationID].effectiveAllocationStake = 0;
        // Initialize accumulated rewards per stake allocated
        allocations[_createAllocationData.allocationID].accRewardsPerAllocatedToken = (_createAllocationData.tokens > 0) ? _updateRewardsWithAllocation(_createAllocationData.curationId) : 0;

        // // -- Rewards Distribution --
        // // Process non-zero-allocation rewards tracking
        // if (_createAllocationData.tokens > 0) {
        //     // Mark allocated tokens as used
        //     _stakingPools[_createAllocationData.curationId].tokensAllocated.add(alloc.tokens);
        // }

        emit Events.AllocationCreated(
            _createAllocationData.curationId,
            0,
            _createAllocationData.tokens,
            _createAllocationData.allocationID,
            _createAllocationData.metadata,
            block.timestamp
        );
    }

    /**
     * @notice curator or operator can close an allocation.
     * Stakeholders (delegators or seller) are also allowed but only after maxAllocationEpochs passed
     * 
     * @param _allocationID _allocationID
     * @param _epochs epochs
     */
    function _canCloseAllocation(
        address _allocationID,
        uint256 _epochs
    )
        private
        view
        returns (bool)
    {
        DataTypes.Allocation storage _alloc = allocations[_allocationID];

        // Stakeholders (delegators or seller) are also allowed but only after maxAllocationEpochs passed
        bool isCurator = _isAuth(_alloc.curator);
        if (_epochs > maxAllocationEpochs) {
            require(
                isCurator || 
                isDelegator(_alloc.curationId, msg.sender) || 
                isSeller(_allocationID, msg.sender), 
                "!auth-or-del-or-sel");
        } else {
            require(isCurator, "!auth");
        }
        return isCurator;
    }

    /**
     * @notice Close an allocation and free the staked tokens.
     * @param _allocationID The allocation identifier
     */
    function _closeAllocation(address _allocationID, uint256 _stakeToCuration) 
        private 
    {
        // Allocation must exist and be active
        DataTypes.AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState == DataTypes.AllocationState.Active, "!active");

        // Get allocation
        DataTypes.Allocation storage alloc = allocations[_allocationID];

        // Validate that an allocation cannot be closed before one epoch
        alloc.closedAtEpoch = epochManager().currentEpoch();
        uint256 epochs = MathUtils.diffOrZero(alloc.closedAtEpoch, alloc.createdAtEpoch);
        require(epochs > 0, "<epochs");

        // Validate that not any caller can close an allocation
        bool isCurator = _canCloseAllocation(_allocationID, epochs);

        // -- Rebate Pool --
        // Calculate effective allocation for the amount of epochs it remained allocated
        alloc.effectiveAllocationStake = _getEffectiveAllocation(maxAllocationEpochs, alloc.tokens, epochs);

        // Account collected fees and effective allocation in rebate pool for the epoch
        DataTypes.RebatePool storage rebatePool = rebates[alloc.closedAtEpoch];
        if (!rebatePool.exists()) {
            rebatePool.init(alphaNumerator, alphaDenominator);
        }
        for(uint256 i = 0; i < alloc.collectedFees.currencies.length; i ++){
            address _curCurrency = alloc.collectedFees.currencies[i];
            rebatePool.addToPool(_curCurrency, alloc.collectedFees.fees[_curCurrency], alloc.effectiveAllocationStake);
        }

        // -- Rewards Distribution --

        // Process non-zero-allocation rewards tracking
        if (alloc.tokens > 0) {
            // Distribute rewards
            _distributeRewards(_allocationID, _stakeToCuration);
        }

        emit Events.AllocationClosed(
            alloc.curationId,
            alloc.closedAtEpoch,
            alloc.tokens,
            _allocationID,
            alloc.effectiveAllocationStake,
            msg.sender,
            _stakeToCuration,
            isCurator,
            block.timestamp
        );
    }

    /**
     * @dev Claim tokens from the rebate pool.
     * @param _allocationID Allocation from where we are claiming tokens
     * @param _stakeToCuration Restake to othe curation.
     */
    function _claim(address _allocationID, uint256 _stakeToCuration)
        private 
    {
        // Funds can only be claimed after a period of time passed since allocation was closed
        DataTypes.AllocationState allocState = _getAllocationState(_allocationID);
        require(allocState == DataTypes.AllocationState.Finalized, "!finalized");

        // Get allocation
        DataTypes.Allocation storage alloc = allocations[_allocationID];

        // Only the curator or operator can decide if to restake
        _stakeToCuration = _isAuth(alloc.curator) ? _stakeToCuration : 0;

        (   
            address[] memory sellers,
            address[] memory sellerFundsRecipients,
            uint32[] memory sellerBpses,
            uint32 stakingBps
        ) = abi.decode(
            alloc.recipientsMeta, 
            (address[], address[], uint32[], uint32)
        );

        // Process rebate reward
        DataTypes.RebatePool storage rebatePool = rebates[alloc.closedAtEpoch];
        unchecked {
            // withdraw fees collected.
            uint256 tokensToClaim;
            uint256 delegationRewards;
            uint256 remainingRewards;
            address curCurrency;
            uint256 _reward;

            for(uint256 i = 0; i < alloc.collectedFees.currencies.length; i++){
                curCurrency = alloc.collectedFees.currencies[i];
                tokensToClaim = rebatePool.redeem(curCurrency, alloc.collectedFees.fees[curCurrency], alloc.effectiveAllocationStake);
                if (tokensToClaim <= 0){
                    continue;
                }
                // Add delegation rewards to the delegation pool
                delegationRewards = _collectDelegationRewardsAndFees(alloc.curationId, curCurrency, tokensToClaim, stakingBps);
                remainingRewards = tokensToClaim.sub(delegationRewards);

                // When there are tokens to claim from the rebate pool, transfer or restake
                // Send the split rewards
                for(uint256 j = 0; j < sellers.length; j++){
                    _reward = uint256(sellerBpses[j]).mul(remainingRewards).div(Constants.MAX_BPS);
                    if (_reward <= 0){
                        continue;
                    }
                    // restake
                    if (curCurrency == address(bardsCurationToken()) && 
                            sellers[j] == alloc.curator && 
                                _stakeToCuration != 0){
                        _stake(_stakeToCuration, _reward, alloc.curator);
                        continue;
                    }
                    
                    // Transfer funds to the beneficiary
                    TokenUtils.transfer(
                        IERC20(curCurrency),
                        stakingAddress,
                        _reward,
                        sellerFundsRecipients[j]
                    );
                }
                uint256 _closeAtEpoch = alloc.closedAtEpoch;
                emit Events.RebateClaimed(
                    alloc.curationId,
                    _allocationID,
                    curCurrency,
                    epochManager().currentEpoch(),
                    _closeAtEpoch,
                    tokensToClaim,
                    rebatePool.unclaimedAllocationsCount,
                    delegationRewards,
                    block.timestamp
                );
            }
        }
        
        // Purge allocation data
        allocations[_allocationID].tokens = 0;
        allocations[_allocationID].createdAtEpoch = 0; // This avoid collect(), close() and claim() to be called
        allocations[_allocationID].closedAtEpoch = 0;
        allocations[_allocationID].effectiveAllocationStake = 0;
        allocations[_allocationID].accRewardsPerAllocatedToken = 0;

        // -- Interactions --
        // When all allocations processed then burn unclaimed fees and prune rebate pool
        if (rebatePool.unclaimedAllocationsCount == 0) {
            IBardsCurationToken bct = bardsCurationToken();
            TokenUtils.burnTokens(bct, rebatePool.unclaimedFees(address(bct)));
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
     * @param _maxAllocationEpochs maxAllocationEpochs
     * @param _tokens Amount of tokens allocated
     * @param _numEpochs Number of epochs that passed from allocation to closing
     * @return Effective allocated tokens across epochs
     */
    function _getEffectiveAllocation(
        uint256 _maxAllocationEpochs,
        uint256 _tokens,
        uint256 _numEpochs
    ) 
        private 
        pure 
        returns (uint256) 
    {
        bool shouldCap = _maxAllocationEpochs > 0 && _numEpochs > _maxAllocationEpochs;
        return _tokens.mul((shouldCap) ? _maxAllocationEpochs : _numEpochs);
    }

    /**
     * @notice Assign rewards for the closed allocation to creators and delegators.
     * TODO support re-stake
     * 
     * @param _allocationID Allocation
     * @param _stakeToCuration _stakeToCuration
     */
    function _distributeRewards(address _allocationID, uint256 _stakeToCuration) 
        private 
    {
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
            address[] memory sellers,
            address[] memory sellerFundsRecipients,
            uint32[] memory sellerBpses,
            uint32 stakingBps
        ) = abi.decode(
            allocations[_allocationID].recipientsMeta, 
            (address[], address[], uint32[], uint32)
        );

        IBardsCurationToken bct = bardsCurationToken();

        // Calculate delegation rewards and add them to the delegation pool
        uint256 delegationRewards = _collectDelegationRewardsAndFees(
            allocations[_allocationID].curationId, 
            address(bct), 
            totalRewards, 
            stakingBps
        );
        uint256 remainingRewards = totalRewards.sub(delegationRewards);

        unchecked {
            // Send the split rewards
            uint256 _reward;
            address _curator = allocations[_allocationID].curator;
            for(uint256 i = 0; i < sellers.length; i++){
                _reward = uint256(sellerBpses[i]).mul(remainingRewards).div(Constants.MAX_BPS);
                if(_reward <= 0){
                    continue;
                }
                if (sellers[i] == allocations[_allocationID].curator && _stakeToCuration != 0){
                    _stake(_stakeToCuration, _reward, _curator);
                    continue;
                }
                TokenUtils.transfer(
                    bct,
                    stakingAddress, 
                    _reward, 
                    sellerFundsRecipients[i]
                );
            }
        }
        
    }

    /**
     * @notice Collect the delegation rewards.
     * This function will assign the collected fees to the delegation pool.
     * @param _curationId Curation to which the tokens to distribute are related
     * @param _currency The currency of token.
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     * @param _rewardAndFeeCut The reward cut percent for delegation.
     * @return Amount of delegation rewards
     */
    function _collectDelegationRewardsAndFees(
        uint256 _curationId, 
        address _currency, 
        uint256 _tokens, 
        uint32 _rewardAndFeeCut
    )
        private
        returns (uint256)
    {
        uint256 delegationRewards = 0;
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        
        if (_rewardAndFeeCut <= Constants.MAX_BPS) {
            delegationRewards = uint256(_rewardAndFeeCut).mul(_tokens).div(Constants.MAX_BPS);
            if (delegationRewards <= 0){
                return 0;
            }
            if (_currency == address(bardsCurationToken())){
                stakingPool.tokens = stakingPool.tokens.add(delegationRewards);
            }else{
                uint256 _currentEpoch = epochManager().currentEpoch();
                stakingPool.fees[_currentEpoch].fees[_currency] = stakingPool.fees[_currentEpoch].fees[_currency].add(delegationRewards);
            }
        }
        return delegationRewards;
    }
}