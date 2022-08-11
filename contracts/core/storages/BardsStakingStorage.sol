// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../utils/DataTypes.sol';

abstract contract BardsStakingStorage {
	// Tax charged when delegator deposit funds
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public stakingTaxPercentage;

    // Default staking reserve ratio to configure delegator shares bonding curve
    // Parts per million. (Allows for 4 decimal points, 999,999 = 99.9999%)
    uint32 public defaultStakingReserveRatio;

    // Master copy address that holds implementation of curation staking token
    // This is used as the target for BardsCurationToken clones
    address public curationStakingTokenMaster;

    // Minimum amount allowed to be deposited by curators to initialize a pool
    // This is the `startPoolBalance` for the bonding curve
    uint256 public minimumCurationStaking;

    // Bonding curve library
    address public bondingCurve;

    // Mapping of curationId => CurationStakingPool
    // There is only one CurationStakingPool per curationId
	mapping (uint256 => DataTypes.StakingStruct) _stakingPools;
}