// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.12;

import {DataTypes} from "./DataTypes.sol";

library CodeUtils {
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

	function decodeCurationMetaData(
		bytes memory curationMetaData
	)
		internal
		pure
		returns (DataTypes.CurationData memory)
	{
		(
            address[] memory sellerFundsRecipients,
            uint256[] memory curationFundsRecipients,
            uint32[] memory sellerFundsBpses,
            uint32[] memory curationFundsBpses,
            uint32 curationBps,
            uint32 stakingBps
        ) = abi.decode(
            curationMetaData, 
            (address[], uint256[], uint32[], uint32[], uint32, uint32)
        );

		return DataTypes.CurationData({
			sellerFundsRecipients: sellerFundsRecipients,
			curationFundsRecipients: curationFundsRecipients,
			sellerFundsBpses: sellerFundsBpses,
			curationFundsBpses: curationFundsBpses,
			curationBps: curationBps,
			stakingBps: stakingBps,
			updatedAtBlock: 0
		});
	}

	function encodeCurationMetaData(
		DataTypes.CurationData memory curationMetaData
	)
		internal
		pure
		returns (bytes memory)
	{
		bytes memory _metaData = abi.encode(
			curationMetaData.sellerFundsRecipients, 
			curationMetaData.curationFundsRecipients,
			curationMetaData.sellerFundsBpses,
			curationMetaData.curationFundsBpses,
			curationMetaData.curationBps,
			curationMetaData.stakingBps
        );

		return _metaData;
	}

	function encodeDefaultProfileWithSigMessage(
		DataTypes.SetDefaultProfileWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH,
				vars.wallet,
				vars.profileId,
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodeCurationContentURIWithSigMessage(
		DataTypes.SetCurationContentURIWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				SET_CURATION_CONTENT_URI_WITH_SIG_TYPEHASH,
				vars.curationId,
				keccak256(bytes(vars.contentURI)),
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodeAllocationIdWithSigMessage(
		DataTypes.SetAllocationIdWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				SET_ALLOCATION_ID_WITH_SIG_TYPEHASH,
				vars.curationId,
				vars.allocationId,
				keccak256(vars.curationMetaData),
				vars.stakeToCuration,
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodeMarketModuleWithSigMessage(
		DataTypes.SetMarketModuleWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				SET_MARKET_MODULE_WITH_SIG_TYPEHASH,
				vars.curationId,
				vars.tokenContract,
				vars.tokenId,
				vars.marketModule,
				keccak256(vars.marketModuleInitData),
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodeCreateCurationWithSigMessage(
		DataTypes.CreateCurationWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure 
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				CREATE_CURATION_WITH_SIG_TYPEHASH,
				vars.profileId,
				vars.tokenContractPointed,
				vars.tokenIdPointed,
				keccak256(bytes(vars.contentURI)),
				vars.marketModule,
				keccak256(vars.marketModuleInitData),
				vars.minterMarketModule,
				keccak256(vars.minterMarketModuleInitData),
				keccak256(vars.curationMetaData),
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodecollectWithSigMessage(
		DataTypes.DoCollectWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				COLLECT_WITH_SIG_TYPEHASH,
				vars.curationId,
				keccak256(vars.collectMetaData),
				nonce,
				vars.sig.deadline
			)
		);
	}


}