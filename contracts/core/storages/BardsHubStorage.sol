// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

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
	// Track contract ids to contract address
    mapping(bytes32 => address) internal _registry;
    mapping(address => bool) internal _isRegisteredAddress;

	// address -> profile id
	mapping(address => uint256) internal _defaultProfileByAddress;
	// whitelists
	mapping(address => bool) internal _marketModuleWhitelisted;
	mapping (address => bool) internal _minterModuleWhitelisted;
	mapping(address => bool) internal _profileCreatorWhitelisted;
    mapping(address => bool) internal _currencyWhitelisted;

	// hash -> profile id
	mapping(bytes32 => uint256) internal _profileIdByHandleHash;
	// self curation or profile
	mapping(uint256 => bool) internal _isProfileById;
    // curator => allocationId => bool
    mapping(address => mapping(uint256 => bool)) internal _isToBeClaimedByAllocByCurator;
	// curation
	mapping(uint256 => DataTypes.CurationStruct) internal _curationById;
	// curation id (or profile) -> curation id -> bool
	// mapping(uint256 => mapping(uint256 => bool)) internal _isMintedByIdById;

    uint256 internal _curationCounter;
    uint256 internal _allocationCounter;
    address internal _governance;
    address internal _emergencyAdmin;
}