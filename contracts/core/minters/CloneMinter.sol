// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IProgrammableMinter} from '../../interfaces/minters/IProgrammableMinter.sol';
import {ContractRegistrar} from '../govs/ContractRegistrar.sol';
import {IBardsHub} from '../../interfaces/IBardsHub.sol';
import {DataTypes} from '../../utils/DataTypes.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';


/**
 * @title CloneMinter
 * 
 * @author TheBards Protocol
 * 
 * @notice Minting in the form of cloning.
 */
contract CloneMinter is ContractRegistrar, IProgrammableMinter {

	constructor(
        address _hub
    ) {
        ContractRegistrar._initialize(_hub);
    }
	
    /// @inheritdoc IProgrammableMinter
	function mint(
		bytes memory metaData
	) 
		external 
		override
		returns (address, uint256)
	{	
		IBardsHub hub = bardsHub();
		uint256 tokenId; 
		(
			uint256 cloneFromCuration,
			address to,
			string memory handle,
			bytes memory marketModuleInitData,
			bytes memory minterMarketModuleInitData,
			bytes memory curationMetaData
		) = abi.decode(
			metaData,
			(uint256, address, string, bytes, bytes, bytes)
		);

		DataTypes.CurationStruct memory curCuration = hub.getCuration(cloneFromCuration);

		address curTokenContractPointed = curCuration.tokenContractPointed != HUB? curCuration.tokenContractPointed: address(0);

		DataTypes.CreateCurationData memory createCurationData = DataTypes.CreateCurationData({
				to: to,
				curationType: curCuration.curationType,
				profileId: hub.defaultProfile(to),
				curationId: 0,
				tokenContractPointed: curTokenContractPointed,
				tokenIdPointed: curCuration.tokenIdPointed,
				handle: handle,
				contentURI: curCuration.contentURI,
				marketModule: curCuration.marketModule,
				marketModuleInitData: marketModuleInitData,
				minterMarketModule: curCuration.minterMarketModule,
				minterMarketModuleInitData: minterMarketModuleInitData,
				curationMetaData: curationMetaData,
				curationFrom: cloneFromCuration
		});

		if (curCuration.curationType == DataTypes.CurationType.Profile){
			tokenId = hub.createProfile(createCurationData);
		} else {
			tokenId = hub.createCuration(createCurationData);
		}
		
		return (address(hub), tokenId);
	}
}