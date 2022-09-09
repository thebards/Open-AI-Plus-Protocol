// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/minters/IProgrammableMinter.sol';
import '../govs/ContractRegistrar.sol';
import '../../interfaces/IBardsHub.sol';
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
			DataTypes.CreateCurationData memory vars,
			bool isProfile
		) = abi.decode(
			metaData,
			(DataTypes.CreateCurationData, bool)
		);
		if (isProfile == true){
			tokenId = hub.createProfile(vars);
		} else {
			tokenId = hub.createCuration(vars);
		}
		
		return (address(hub), tokenId);
	}
}