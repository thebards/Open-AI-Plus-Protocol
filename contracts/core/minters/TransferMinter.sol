// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {VersionedInitializable} from '../../upgradeablity/VersionedInitializable.sol';
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
contract TransferMinter is 
	VersionedInitializable, 
	ContractRegistrar, 
	IProgrammableMinter {

    uint256 internal constant REVISION = 1;

	// constructor(
    //     address _hub
    // ) {
    //     ContractRegistrar._initialize(_hub);
    // }

	/// @inheritdoc IProgrammableMinter
    function initialize(
        address _hub
    )
	    external 
        override 
        initializer
	{
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

    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }
}