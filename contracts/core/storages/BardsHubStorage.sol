// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title BardsHubStorage
 * @author TheBards Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the BardsHub contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the BardsHub storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract BardsHubStorage {
	uint256 internal _curationCounter;
    address internal _governance;
    address internal _emergencyAdmin;

	// address -> profile id
	mapping(address => uint256) internal _defaultProfileByAddress;

	// whitelists
	mapping(address => bool) internal _marketModuleWhitelisted;
	mapping(address => bool) internal _profileCreatorWhitelisted;

	// hash -> profile id
	mapping(bytes32 => uint256) internal _profileIdByHandleHash;

	// self curation or profile
	mapping(uint256 => DataTypes.ProfileCurationStruct) internal _profileById;
	// curation
	mapping(uint256 => DataTypes.CurationStruct) internal _curationById;

	// profile id -> curation id -> bool
	mapping(uint256 => mapping(uint256 => bool)) internal _isCuratedByIdByProfile;

}