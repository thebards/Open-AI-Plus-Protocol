// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/tokens/IBardsStaking.sol';
import '../storages/BardsStakingStorage.sol';
import '../tokens/BardsShareToken.sol';
import '../tokens/BardsCurationToken.sol';
import '../../utils/DataTypes.sol';
import '../../utils/Errors.sol';
import '../../utils/Events.sol';
import '../../utils/Constants.sol';
import '../../interfaces/tokens/IBardsShareToken.sol';
import '../../interfaces/tokens/IBardsCurationToken.sol';
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
contract BardsStaking is IBardsStaking, BardsStakingStorage {
	using SafeMath for uint256;

	address private HUB;

	modifier onlyHub() {
        require(msg.sender == HUB, "Only HUB can call");
        _;
    }
	
	/**
     * @dev Initialize this contract.
     */
    function initialize(
		address _HUB,
        address _bondingCurve,
        address _curationStakingTokenMaster,
        uint32 _defaultStakingReserveRatio,
        uint32 _stakingTaxPercentage,
        uint256 _minimumCurationStaking
    ) external {
		if (_HUB == address(0)) revert Errors.InitParamsInvalid();
        require(_bondingCurve != address(0), "Bonding curve must be set");
        bondingCurve = _bondingCurve;

        // Settings
		_setCurationStakingTokenMaster(_curationStakingTokenMaster);
        _setDefaultStakingReserveRatio(_defaultStakingReserveRatio);
        _setStakingTaxPercentage(_stakingTaxPercentage);
        _setMinimumCurationStaking(_minimumCurationStaking);
    }

    /// @inheritdoc IBardsStaking
    function setDefaultStakingReserveRatio(uint32 _defaultReserveRatio) 
		external 
		override 
	onlyHub {
        _setDefaultStakingReserveRatio(_defaultReserveRatio);
    }

    /// @inheritdoc IBardsStaking
    function setMinimumCurationStaking(uint256 _minimumCurationDeposit)
        external
        override
    onlyHub{
        _setMinimumCurationStaking(_minimumCurationDeposit);
    }

    /// @inheritdoc IBardsStaking
	function setStakingTaxPercentage(uint32 _percentage) 
		external 
		override 
	onlyHub {
        _setStakingTaxPercentage(_percentage);
    }

    /// @inheritdoc IBardsStaking
    function setCurationStakingTokenMaster(address _curationStakingTokenMaster) 
		external 
		override 
	onlyHub {
        _setCurationStakingTokenMaster(_curationStakingTokenMaster);
    }

    /// @inheritdoc IBardsStaking
	function earn(uint256 _curationId, uint256 _amount) 
		external 
		override onlyHub {
        // Must be curated to accept tokens
        require(
            isStaked(_curationId),
            "Curation must be built to earn fees"
        );

        // Collect new funds into reserve
        DataTypes.StakingStruct storage stakingPool = _stakingPools[_curationId];
        stakingPool.amount = stakingPool.amount.add(_amount);

        emit Events.StakingPoolEarned(_curationId, _amount, block.timestamp);
    }

    /// @inheritdoc IBardsStaking
	function mint(
        uint256 _curationId,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external override returns (uint256, uint256) {
        // Need to deposit some funds
        require(_tokensIn > 0, "Cannot deposit zero tokens");

        // Exchange BCT tokens for BST of the curation staking pool
        (uint256 signalOut, uint256 stakingTax) = tokensToSignal(_curationId, _tokensIn);

        // Slippage protection
        require(signalOut >= _signalOutMin, "Slippage protection");

        address delegator = msg.sender;
        DataTypes.StakingStruct storage stakingPool = _stakingPools[_curationId];

        // If it hasn't been curated before then initialize the curve
        if (!isStaked(_curationId)) {
            stakingPool.reserveRatio = defaultStakingReserveRatio;

            // If no signal token for the pool - create one
            if (stakingPool.bst == address(0)) {
                // Use a minimal proxy to reduce gas cost
                IBardsShareToken bst = IBardsShareToken(Clones.clone(curationStakingTokenMaster));
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
        IBardsCurationToken _bardsCurationToken = BardsCurationToken();
		if (_tokensIn > 0) {
            require(_bardsCurationToken.transferFrom(delegator, address(this), _tokensIn), "!transfer");
        }
		if (stakingTax > 0){
			_bardsCurationToken.burn(stakingTax);
		}

        // Update curation staking pool
        stakingPool.amount = stakingPool.amount.add(_tokensIn.sub(stakingTax));
        IBardsShareToken(stakingPool.bst).mint(delegator, signalOut);

        emit Events.Signalled(delegator, _curation, _tokensIn, signalOut, stakingTax, block.timestamp);

        return (signalOut, stakingTax);
    }

    /// @inheritdoc IBardsStaking
    function burn(
        uint256 _curationId,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external override returns (uint256) {
        address delegator = msg.sender;

        // Validations
        require(_signalIn > 0, "Cannot burn zero signal");
        require(
            getDelegatorSignal(delegator, _curationId) >= _signalIn,
            "Cannot burn more signal than you own"
        );

        // Get the amount of tokens to refund based on returned signal
        uint256 tokensOut = signalToTokens(_curationId, _signalIn);

        // Slippage protection
        require(tokensOut >= _tokensOutMin, "Slippage protection");

        // Trigger update rewards calculation
        // _updateRewards(_subgraphDeploymentID);

        // Update curation pool
        DataTypes.StakingStruct storage stakingPool = _stakingPools[_curationId];
        stakingPool.amount = stakingPool.amount.sub(tokensOut);
        IBardsShareToken(stakingPool.bst).burnFrom(delegator, _signalIn);

        // If all signal burnt delete the curation pool except for the
        // curation token contract to avoid recreating it on a new mint
        if (getCurationStakingPoolSignal(_curationId) == 0) {
            stakingPool.amount = 0;
            stakingPool.reserveRatio = 0;
        }

        // Return the tokens to the delegator
		if (tokensOut > 0) {
            require(BardsCurationToken().transfer(delegator, tokensOut), "!transfer");
        }

        emit Events.Burned(delegator, _curationId, tokensOut, _signalIn, block.timestamp);

        return tokensOut;
    }

    /// @inheritdoc IBardsStaking
    function isStaked(uint256 _curationId) 
		public 
		view 
		override 
	returns (bool) {
        return _stakingPools[_curationId].amount > 0;
    }

    /// @inheritdoc IBardsStaking
    function getDelegatorSignal(address _delegator, uint256 _curationId)
        public
        view
        override
        returns (uint256)
    {
        address bst = _stakingPools[_curationId].bst;
        return (bst == address(0)) ? 0 : BardsShareToken(gcs).balanceOf(_delegator);
    }

    /// @inheritdoc IBardsStaking
    function getCurationStakingPoolSignal(uint256 _curationId)
        public
        view
        override
        returns (uint256)
    {
        address bst = _stakingPools[_curationId].bst;
        return (bst == address(0)) ? 0 : BardsShareToken(gcs).totalSupply();
    }

    /// @inheritdoc IBardsStaking
    function getCurationStakingPoolTokens(uint256 _curationId)
        external
        view
        override
        returns (uint256)
    {
        return _stakingPools[_curationId].amount;
    }

    /// @inheritdoc IBardsStaking
    function tokensToSignal(uint256 _curationId, uint256 _tokensIn)
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 stakingTax = _tokensIn.mul(uint256(stakingTaxPercentage)).div(Constants.MAX_BPS);
        uint256 signalOut = _tokensToSignal(_curationId, _tokensIn.sub(stakingTax));
        return (signalOut, stakingTax);
    }

    /**
     * @dev Calculate amount of signal that can be bought with tokens in a curation staking pool.
     * @param _curationId Curation to mint signal
     * @param _tokensIn Amount of tokens used to mint signal
     * @return Amount of signal that can be bought with tokens
     */
    function _tokensToSignal(uint256 _curationId, uint256 _tokensIn)
        private
        view
        returns (uint256)
    {
        // Get curation pool tokens and signal
        DataTypes.StakingStruct storage stakingPool = _stakingPools[_curationId];

        // Init curation pool
        if (stakingPool.amount == 0) {
            require(
                _tokensIn >= minimumCurationStaking,
                "Curation staking is below minimum required"
            );
            return
                BancorFormula(bondingCurve)
                    .calculatePurchaseReturn(
                        Constants.SIGNAL_PER_MINIMUM_DEPOSIT,
                        minimumCurationStaking,
                        defaultStakingReserveRatio,
                        _tokensIn.sub(minimumCurationStaking)
                    )
                    .add(Constants.SIGNAL_PER_MINIMUM_DEPOSIT);
        }

        return
            BancorFormula(bondingCurve).calculatePurchaseReturn(
                getCurationStakingPoolSignal(_curationId),
                stakingPool.amount,
                stakingPool.reserveRatio,
                _tokensIn
            );
    }

    /// @inheritdoc IBardsStaking
    function signalToTokens(uint256 _curationId, uint256 _signalIn)
        public
        view
        override
        returns (uint256)
    {
         DataTypes.StakingStruct storage stakingPool = _stakingPools[_curationId];
        uint256 curationStakingPoolSignal = getCurationStakingPoolSignal(_curationId);
        require(
            stakingPool.amount > 0,
            "Curation must be built to perform calculations"
        );
        require(
            curationStakingPoolSignal >= _signalIn,
            "Signal must be above or equal to signal issued in the curation staking pool"
        );

        return
            BancorFormula(bondingCurve).calculateSaleReturn(
                curationStakingPoolSignal,
                stakingPool.amount,
                stakingPool.reserveRatio,
                _signalIn
            );
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
    function _setDefaultStakingReserveRatio(
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
     * @notice Update the minimum staking amount to `minimumCurationStaking`
     * @param _newMinimumCurationStaking Minimum amount of tokens required staking
     */
    function _setMinimumCurationStaking(
		uint256 _newMinimumCurationStaking
	) private {
        require(_newMinimumCurationStaking > 0, "Minimum curation deposit cannot be 0");

		uint256 prevMinimumCurationStaking = minimumCurationStaking;	
        minimumCurationStaking = _newMinimumCurationStaking;

        emit Events.MinimumCurationStakingSet(
			prevMinimumCurationStaking, 
			_newMinimumCurationStaking, 
			block.timestamp
		);
    }

    /**
     * @dev Internal: Set the master copy to use as clones for the curation token.
     * @param _newCurationStakingTokenMaster Address of implementation contract to use for curation staking tokens
     */
    function _setCurationStakingTokenMaster(address _newCurationStakingTokenMaster) private {
        require(_newCurationStakingTokenMaster != address(0), "Token master must be non-empty");
        require(Address.isContract(_newCurationStakingTokenMaster), "Token master must be a contract");

		address prevCurationStakingTokenMaster = curationStakingTokenMaster;
        curationStakingTokenMaster = _newCurationStakingTokenMaster;
        emit Events.CurationStakingTokenMasterSet(
			prevCurationStakingTokenMaster,
			_newCurationStakingTokenMaster,
			block.timestamp
		);
    }

}