// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/tokens/IBardsStaking.sol';
import '../storages/BardsStakingStorage.sol';
import '../../utils/DataTypes.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


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
	

}