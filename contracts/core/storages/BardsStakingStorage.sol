// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../utils/DataTypes.sol';

abstract contract BardsStakingStorage {
    // Total staking tokens.
    uint256 totalStakingTokens;
    // The address of staking tokens;
    address public stakingAddress;

	// Tax charged when delegator deposit funds
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public stakingTaxPercentage;

    // Default staking reserve ratio to configure delegator shares bonding curve
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public defaultStakingReserveRatio;

    // Master copy address that holds implementation of bards share token
    // This is used as the target for BardsShareToken clones
    address public bardsShareTokenImpl;

    // Minimum amount allowed to be deposited by curators to initialize a pool
    // This is the `startPoolBalance` for the bonding curve
    uint256 public minimumStaking;

    // Bonding curve library
    address public bondingCurve;

    // Time in blocks to unstake
    uint32 public thawingPeriod; // in blocks

    // Period for allocation to be finalized
    uint32 public channelDisputeEpochs;

    // Maximum allocation time
    uint32 public maxAllocationEpochs;

    // Rebate ratio
    uint32 public alphaNumerator;
    uint32 public alphaDenominator;

    // Operator auth : sender => operator
    mapping(address => mapping(address => bool)) public operatorAuth;

    // Mapping of curationId => CurationStakingPool
    // There is only one CurationStakingPool per curationId
	mapping (uint256 => DataTypes.CurationStakingPool) _stakingPools;

    // Allocations : allocationID => Allocation
    mapping(address => DataTypes.Allocation) allocations;

    // Rebate pools : epoch => Pool
    mapping(uint256 => DataTypes.RebatePool) rebates;
}