// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/minters/IProgrammableMinter.sol';
import '../govs/ContractRegistrar.sol';
import '../../interfaces/IBardsHub.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "hardhat/console.sol";

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
				curationMetaData: curationMetaData
		});

		if (curCuration.curationType == DataTypes.CurationType.Profile){
			tokenId = hub.createProfile(createCurationData);
		} else {
			console.log('9.5');
			tokenId = hub.createCuration(createCurationData);
			console.log('9.8');
		}
		
		return (address(hub), tokenId);
	}
}