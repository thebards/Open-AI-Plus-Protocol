// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IProgrammableMinter} from '../../interfaces/minters/IProgrammableMinter.sol';
import {ContractRegistrar} from '../govs/ContractRegistrar.sol';
import {IBardsHub} from '../../interfaces/IBardsHub.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title EmptyMinter
 * 
 * @author TheBards Protocol
 * 
 * @notice Do Nothing.
 */
contract EmptyMinter is ContractRegistrar, IProgrammableMinter {

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
		pure
		override
		returns (address, uint256)
	{	
		(
			address tokenContract,
			uint256 tokenId
		) = abi.decode(
			metaData,
			(address, uint256)
		);
		
		return (tokenContract, tokenId);
	}
}