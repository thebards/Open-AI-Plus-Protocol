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
contract BardsStaking is IBardsStaking, BardsStakingStorage, ContractRegistrar {
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
        emit SetOperator(msg.sender, _operator, _allowed);
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
	function collect(uint256 _curationId, uint256 _tokens, address currency) 
		external 
		override onlyHub {
        // Must be curated to accept tokens
        require(
            isStaked(_curationId),
            "Curation must be built to earn fees"
        );

        // Collect new funds into reserve
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        stakingPool.tokens[currency] = stakingPool.tokens[currency].add(_tokens);

        emit Events.StakingPoolEarned(_curationId, _tokens, block.timestamp);
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
        external 
        override 
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

        // TODO Trigger update rewards calculation snapshot
        // _updateRewards(_subgraphDeploymentID);

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
        Delegation storage delegation = stakingPool.delegators[_delegator];
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
    ) external override returns (uint256) {
        // Validations
        require(_shares > 0, "Cannot burn zero signal");
        require(
            getDelegatorShare(delegator, _curationId) >= _shares,
            "Cannot burn more share than you own"
        );

        // Slippage protection
        // require(tokensOut >= _tokensOutMin, "Slippage protection");

        // Trigger update rewards calculation
        // _updateRewards(_subgraphDeploymentID);

        // Update curation pool
        DataTypes.CurationStakingPool storage stakingPool = _stakingPools[_curationId];
        // Update the individual delegation
        Delegation storage delegation = stakingPool.delegators[_delegator];

        // Withdraw tokens if available
        if (getWithdraweableBCTTokens(delegation) > 0) {
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

    /**
     * @notice Returns amount of staked BCT tokens ready to be withdrawn after thawing period.
     * @param _delegation Delegation of tokens from delegator to curation
     * @return Are there any withdrawable tokens.
     */
    function getWithdraweableBCTTokens(Delegation memory _delegation)
        public
        view
        returns (uint256)
    {
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
	returns (bool) {
        return _stakingPools[_curationId].tokens[address(bardsCurationToken())] > 0;
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
        uint256 tokensToWithdraw = getWithdraweableBCTTokens(delegation);
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
     * @dev Internal: Set the staking tax percentage to charge when a delegator deposits BCT tokens.
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

}