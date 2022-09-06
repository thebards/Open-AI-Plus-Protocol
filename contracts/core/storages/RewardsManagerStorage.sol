// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../utils/DataTypes.sol';

abstract contract RewardsManagerStorage {
	uint256 public issuanceRate;
    // Change in inflation rate per round until the target bonding rate is achieved
    uint256 public inflationChange;
    // Target bonding rate
    uint256 public targetBondingRate;
    
    uint256 public accRewardsPerStaking;
    uint256 public accRewardsPerStakingLastBlockUpdated;

    // // Address of role allowed to deny rewards on subgraphs
    // address public subgraphAvailabilityOracle;

    // Subgraph related rewards: subgraph deployment ID => curation rewards
    mapping(uint256 => DataTypes.CurationReward) public curationRewards;

    // Subgraph denylist : subgraph deployment ID => block when added or zero (if not denied)
    mapping(uint256 => uint256) public denylist;

	// Minimum amount of tokens on a curation required to accrue rewards
    uint256 public minimumStakingToken;
    // Snapshot of the total supply of BCT when accRewardsPerShare was last updated
    uint256 public tokenSupplySnapshot;
}