// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
	bytes32 internal constant SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDefaultProfileWithSig(address wallet,uint256 profileId,uint256 nonce,uint256 deadline)'
        );
	bytes32 internal constant SET_CURATION_CONTENT_URI_WITH_SIG_TYPEHASH =
        keccak256(
            'SetCurationContentURIWithSig(uint256 curationId,string contentURI,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_MARKET_MODULE_WITH_SIG_TYPEHASH =
        keccak256(
            'SetMarketModuleWithSig(uint256 curationId,address tokenContract,uint256 tokenId,address marketModule,bytes marketModuleInitData,uint256 nonce,uint256 deadline)'
        );
	bytes32 internal constant CREATE_CURATION_WITH_SIG_TYPEHASH =
        keccak256(
            'CreateCurationWithSig(uint256 profileId,address tokenContractPointed,uint256 tokenIdPointed,string contentURI,address marketModule,bytes marketModuleInitData,address minterMarketModule,bytes minterMarketModuleInitData,bytes curationMetaData,uint256 nonce,uint256 deadline)'
        );
	bytes32 internal constant COLLECT_WITH_SIG_TYPEHASH =
        keccak256(
            'CollectWithSig(uint256 curationId,bytes collectMetaData,uint256 nonce,uint256 deadline)'
        );
	bytes32 internal constant SET_DISPATCHER_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDispatcherWithSig(uint256 profileId,address dispatcher,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_ALLOCATION_ID_WITH_SIG_TYPEHASH =
        keccak256(
            'SetAllocationIdWithSig(uint256 curationId,uint256 allocationId,bytes curationMetaData,uint256 stakeToCuration,uint256 nonce,uint256 deadline)'
        );

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
	// curation
	mapping(uint256 => DataTypes.CurationStruct) internal _curationById;
	// curation id (or profile) -> curation id -> bool
	mapping(uint256 => mapping(uint256 => bool)) internal _isMintedByIdById;

    uint256 internal _curationCounter;
    uint256 internal _allocationCounter;
    address internal _governance;
    address internal _emergencyAdmin;
}