// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../utils/Constants.sol';
import '../../utils/Events.sol';
import '../storages/RewardsManagerStorage.sol';
import '../../interfaces/tokens/IBardsCurationToken.sol';
import '../govs/ContractRegistrar.sol';
import '../../interfaces/govs/IRewardsManager.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title RewardsManager
 * 
 * @author Thebards Protocol
 * 
 * @notice Tracks how inflationary BCT rewards should be handed out. Relies on
 * the Staking contract. Staked GRT in Curation determine what percentage of the tokens go
 * towards each stakeholder. Then each Curation can have multiple Delegator Staked on it. Thus, the
 * total rewards for the Curation are split up for each Creator and Delegator based on much they have Staked on
 * that Subgraph.
 *
 */
contract RewardsManager is RewardsManagerStorage, ContractRegistrar, IRewardsManager {
	using SafeMath for uint256;

	/**
     * @notice Initialize this contract.
     */
    function initialize(address _HUB) external {
        ContractRegistrar._initialize(_HUB);
	}

	/// @inheritdoc IRewardsManager
    function setIssuanceRate(
		uint256 _issuanceRate
	) 
	external 
	override 
	onlyHub {
        _setIssuanceRate(_issuanceRate);
    }

    /**
     * @dev Sets the issuance rate.
     * @param _issuanceRate Issuance rate
     */
    function _setIssuanceRate(uint256 _issuanceRate) private {
        require(_issuanceRate >= Constants.MIN_ISSUANCE_RATE, "Issuance rate under minimum allowed");

        // Called since `issuance rate` will change
        updateAccRewardsPerStaking();

        uint256 prevIssuanceRate = issuanceRate;
        issuanceRate = _issuanceRate;
        emit Events.IssuanceRateSet(
            prevIssuanceRate, 
            _issuanceRate, 
            block.timestamp
        );
    }

	/// @inheritdoc IRewardsManager
    function setMinimumStakingToken(
		uint256 _minimumStakeingToken
	) 
	external 
	override 
	onlyHub {
        uint256 prevMinimumStakingToken = minimumStakingToken;
        minimumStakingToken = _minimumStakeingToken;
        emit Events.MinimumStakeingTokenSet(
            prevMinimumStakingToken, 
            _minimumStakeingToken, 
            block.timestamp
        );
    }

	/// @inheritdoc IRewardsManager
    function setDenied(
		uint256 _curationId, 
		bool _deny
	)
    external
    override
    onlyHub
    {
        _setDenied(_curationId, _deny);
    }

	/// @inheritdoc IRewardsManager
    function setDeniedMany(
		uint256[] calldata _curationIds, 
		bool[] calldata _deny
	)
    external
    override
    onlyHub
    {
        require(_curationIds.length == _deny.length, "!length");
        for (uint256 i = 0; i < _curationIds.length; i++) {
            _setDenied(_curationIds[i], _deny[i]);
        }
    }

    /**
     * @dev Internal: Denies to claim rewards for a curation.
     * @param _curationId Curation ID
     * @param _deny Whether to set the curation as denied for claiming rewards or not
     */
    function _setDenied(
		uint256 _curationId, 
		bool _deny
	) 
	private {
        uint256 sinceBlock = _deny ? block.number : 0;
        denylist[_curationId] = sinceBlock;
        emit Events.RewardsDenylistUpdated(_curationId, sinceBlock, block.timestamp);
    }

	/// @inheritdoc IRewardsManager
    function isDenied(
		uint256 _curationId
	) 
	public 
	view 
	override 
	returns (bool) {
        return denylist[_curationId] > 0;
    }

	/// @inheritdoc IRewardsManager
    function getNewRewardsPerStaking() public view override returns (uint256) {
        // Calculate time steps
        uint256 t = block.number.sub(accRewardsPerStakingLastBlockUpdated);
        // Optimization to skip calculations if zero time steps elapsed
        if (t == 0) {
            return 0;
        }

        // Zero issuance under a rate of 1.0
        if (issuanceRate <= Constants.MIN_ISSUANCE_RATE) {
            return 0;
        }

        // Zero issuance if no staked tokens
        IBardsCurationToken bardsCurationToken = bardsCurationToken();
        uint256 stakedTokens = bardsCurationToken.balanceOf(address(bardsStaking()));
        if (stakedTokens == 0) {
            return 0;
        }

        uint256 r = issuanceRate;
        uint256 p = tokenSupplySnapshot;
        uint256 a = p.mul(_pow(r, t, Constants.TOKEN_DECIMALS)).div(Constants.TOKEN_DECIMALS);

        // New issuance of tokens during time steps
        uint256 x = a.sub(p);

        // Get the new issuance per staked token
        // We multiply the decimals to keep the precision as fixed-point number
        return x.mul(Constants.TOKEN_DECIMALS).div(stakedTokens);
    }

	/// @inheritdoc IRewardsManager
    function getAccRewardsPerStaking() public view override returns (uint256) {
        return accRewardsPerStaking.add(getNewRewardsPerStaking());
    }

	/// @inheritdoc IRewardsManager
    function getAccRewardsForCuration(uint256 _curationId)
        public
        view
        override
        returns (uint256)
    {
        DataTypes.CurationReward storage curationReward = curationRewards[_curationId];

        // Get tokens staked on the curation
        uint256 curationStakedTokens = bardsStaking().getCurationStakingPoolTokens(_curationId);

        // Only accrue rewards if over a threshold
        uint256 newRewards = (curationStakedTokens >= minimumStakingToken) // Accrue new rewards since last snapshot
            ? getAccRewardsPerStaking()
                .sub(curationReward.accRewardsPerStakingSnapshot)
                .mul(curationStakedTokens)
                .div(Constants.TOKEN_DECIMALS)
            : 0;
        return curationReward.accRewardsForCuration.add(newRewards);
    }

	/// @inheritdoc IRewardsManager
    function getAccRewardsPerAllocatedToken(uint256 _curationId)
        public
        view
        override
        returns (uint256, uint256)
    {
        DataTypes.CurationReward storage curationReward = curationRewards[_curationId];

        uint256 accRewardsForCuration = getAccRewardsForCuration(_curationId);
        uint256 newRewardsForCuration = accRewardsForCuration.sub(
            curationReward.accRewardsForCurationSnapshot
        );

        // TODO multi-currencies
        uint256 curationAllocatedTokens = bardsStaking().getCurationAllocatedTokens(
            _curationId
        );
        if (curationAllocatedTokens == 0) {
            return (0, accRewardsForCuration);
        }

        uint256 newRewardsPerAllocatedToken = newRewardsForCuration.mul(Constants.TOKEN_DECIMALS).div(curationAllocatedTokens);

        return (
            curationReward.accRewardsPerAllocatedToken.add(newRewardsPerAllocatedToken),
            accRewardsForCuration
        );
    }

	/// @inheritdoc IRewardsManager
    function updateAccRewardsPerStaking() public override returns (uint256) {
        accRewardsPerStaking = getAccRewardsPerStaking();
        accRewardsPerStakingLastBlockUpdated = block.number;
        tokenSupplySnapshot = bardsCurationToken().totalSupply();
        return accRewardsPerStaking;
    }

	/// @inheritdoc IRewardsManager
    function onCurationStakingUpdate(uint256 _curationId)
        external
        override
        returns (uint256)
    {
        // Called since `total staked BCT` will change
        updateAccRewardsPerStaking();

        // Updates the accumulated rewards for a subgraph
        DataTypes.CurationReward storage curationReward = curationRewards[_curationId];

        curationReward.accRewardsForCuration = getAccRewardsForCuration(_curationId);
        curationReward.accRewardsPerStakingSnapshot = accRewardsPerStaking;
        return curationReward.accRewardsForCuration;
    }

	/// @inheritdoc IRewardsManager
    function onCurationAllocationUpdate(uint256 _curationId)
        public
        override
        returns (uint256)
    {
        DataTypes.CurationReward storage curationReward = curationRewards[_curationId];
		(
            uint256 accRewardsPerAllocatedToken,
            uint256 accRewardsForCuration
        ) = getAccRewardsPerAllocatedToken(_curationId);
        curationReward.accRewardsPerAllocatedToken = accRewardsPerAllocatedToken;
        curationReward.accRewardsForCuratiinSnapshot = accRewardsForCuration;
        return curationReward.accRewardsPerAllocatedToken;
    }

	/// @inheritdoc IRewardsManager
    function getRewards(address _allocationID) external view override returns (uint256) {
        DataTypes.Allocation memory alloc = bardsStaking().getAllocation(_allocationID);

        (uint256 accRewardsPerAllocatedToken, ) = getAccRewardsPerAllocatedToken(
            alloc.curationId
        );
        return
            _calcRewards(
                alloc.tokens,
                alloc.accRewardsPerAllocatedToken,
                accRewardsPerAllocatedToken
            );
    }

    /**
     * @notice Calculate current rewards for a given allocation.
     * @param _tokens Tokens allocated
     * @param _startAccRewardsPerAllocatedToken Allocation start accumulated rewards
     * @param _endAccRewardsPerAllocatedToken Allocation end accumulated rewards
     * @return Rewards amount
     */
    function _calcRewards(
        uint256 _tokens,
        uint256 _startAccRewardsPerAllocatedToken,
        uint256 _endAccRewardsPerAllocatedToken
    ) private pure returns (uint256) {
        uint256 newAccrued = _endAccRewardsPerAllocatedToken.sub(_startAccRewardsPerAllocatedToken);
        return newAccrued.mul(_tokens).div(Constants.TOKEN_DECIMALS);
    }

	/// @inheritdoc IRewardsManager
    function takeRewards(address _allocationID) external override returns (uint256) {
        // Only Staking contract is authorized as caller
        IBardsStaking bardStaking = bardsStaking();
        require(msg.sender == address(bardStaking), "Caller must be the bardStaking contract");

        DataTypes.Allocation memory alloc = bardStaking.getAllocation(_allocationID);
        uint256 accRewardsPerAllocatedToken = onCurationAllocationUpdate(
            alloc.curationId
        );

        // Do not do rewards on denied subgraph deployments ID
        if (isDenied(alloc.curationId)) {
            emit Events.RewardsDenied(alloc.curationId, _allocationID, alloc.closedAtEpoch, block.timestamp);
            return 0;
        }

        // Calculate rewards accrued by this allocation
        uint256 rewards = _calcRewards(
            alloc.tokens,
            alloc.accRewardsPerAllocatedToken,
            accRewardsPerAllocatedToken
        );
        if (rewards > 0) {
            // Mint directly to bardsStaking contract for the reward amount
            // The bardsStaking contract will do bookkeeping of the reward and
            // assign in proportion to each stakeholder incentive
            bardsCurationToken().mint(address(bardStaking), rewards);
        }

        emit Events.RewardsAssigned(alloc.curationId, _allocationID, alloc.closedAtEpoch, rewards, block.timestamp);

        return rewards;
    }
}