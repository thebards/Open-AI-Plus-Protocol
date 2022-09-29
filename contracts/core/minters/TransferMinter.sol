// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IProgrammableMinter} from '../../interfaces/minters/IProgrammableMinter.sol';
import {ContractRegistrar} from '../govs/ContractRegistrar.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';


/**
 * @title TransferMinter
 * 
 * @author TheBards Protocol
 * 
 * @notice Minting in the form of transfering.
 */
contract TransferMinter is ContractRegistrar, IProgrammableMinter {

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
		(
			address tokenContract,
			uint256 tokenId,
			address seller,
			address collector
        ) = abi.decode(
            metaData, 
            (address, uint256, address, address)
        );
		if (seller == collector){
			return (tokenContract, tokenId);
		}

		IERC721(tokenContract).safeTransferFrom(seller, collector, tokenId);
		return (tokenContract, tokenId);
	}
}