// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {VersionedInitializable} from '../../upgradeablity/VersionedInitializable.sol';
import {IMarketModule} from '../../interfaces/markets/IMarketModule.sol';
import {IBardsHub} from '../../interfaces/IBardsHub.sol';
import {IBardsCurationBase} from '../../interfaces/curations/IBardsCurationBase.sol';
import {IProgrammableMinter} from '../../interfaces/minters/IProgrammableMinter.sol';
import {MarketModuleBase} from '../trades/MarketModuleBase.sol';
import {DataTypes} from '../../utils/DataTypes.sol';
import {Errors} from '../../utils/Errors.sol';
import {Constants} from '../../utils/Constants.sol';

/**
 * @title FreeMarketModule
 * 
 * @author Thebards Protocol
 * 
 * @notice This module allows sellers to list an owned ERC-721 token for sale for free.
 */
contract FreeMarketModule is 
    VersionedInitializable, 
    MarketModuleBase, 
    IMarketModule {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant REVISION = 1;
	// tokenContract address -> tokenId -> market data
	mapping(address => mapping(uint256 => DataTypes.FreeMarketData)) internal _marketMetaData;

    // constructor(
    //     address _hub, 
    //     address _royaltyEngine,
    //     address _stakingAddress
    // ) {
    //     MarketModuleBase._initialize(_hub, _royaltyEngine, _stakingAddress);
    // }
    
    /// @inheritdoc IMarketModule
    function initialize(
        address _hub, 
        address _royaltyEngine,
        address _stakingAddress
    )   
        external 
        override 
        initializer
    {
        MarketModuleBase._initialize(_hub, _royaltyEngine, _stakingAddress);
    }

    /**
     * @notice Get market meta data.
     */
    function getMarketData(
        address tokenContract,
        uint256 tokenId
    ) 
        external 
        view
        returns (DataTypes.FreeMarketData memory)
    {
        return _marketMetaData[tokenContract][tokenId];
    }

	/** 
     * @notice See {IMarketModule-initializeModule}
     */
	function initializeModule(
		address tokenContract,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes memory) {
		(   
            address seller,
            address minter
        ) = abi.decode(
            data, 
            (address, address)
        );

        if (minter != address(0) && !bardsHub().isMinterModuleWhitelisted(minter)) {
            revert Errors.MinterModuleNotWhitelisted();
        }
		
        _marketMetaData[tokenContract][tokenId].seller = seller;
        _marketMetaData[tokenContract][tokenId].minter = minter;

        return data;
	}

	/**
     * @notice See {IMarketModule-collect}
     */
	function collect(
        address collector,
        uint256 curationId,
		address tokenContract,
        uint256 tokenId,
        uint256[] memory curationIds,
        bytes memory collectMetaData
    ) 
        external 
        override 
        returns (address, uint256)
    {
        collector;
        curationId;
        curationIds;
        DataTypes.FreeMarketData memory marketData = _marketMetaData[tokenContract][tokenId];
        
        (
            address retTokenContract,
            uint256 retTokenId
        ) = IProgrammableMinter(marketData.minter).mint(
            collectMetaData
        );

        delete _marketMetaData[tokenContract][tokenId];

        return (retTokenContract, retTokenId);
	}

    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }
}