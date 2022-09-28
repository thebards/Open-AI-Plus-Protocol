// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '../../interfaces/curations/IBardsCurationBase.sol';
import '../NFTs/BardsNFTBase.sol';
import '../../utils/CurationHelpers.sol';
import '../../utils/Constants.sol';
import '../../utils/Events.sol';
import '../../utils/MathUtils.sol';
import '../../utils/DataTypes.sol';
import '../../utils/CodeUtils.sol';

/**
 * @title BardsCurationBase
 * @author TheBards Protocol
 *
 * @notice This is an abstract base contract to be inherited by other TheBards Protocol Curations, it includes
 * NFT module and curation fee setting module.
 */
abstract contract BardsCurationBase is ReentrancyGuard, IBardsCurationBase, BardsNFTBase {
	/**
     * @notice The curation for a given NFT, if one exists
     * @notice ERC-721 token id => Curation
	 */
    mapping(uint256 => DataTypes.CurationData) internal _curationData;

	// The time in blocks an curator needs to wait to change curation data parameters
	uint32 internal _cooldownBlocks;

	/**
     * @notice Initializer sets the name, symbol and the cached domain separator.
     *
     * NOTE: Inheritor contracts *must* call this function to initialize the name & symbol in the
     * inherited ERC721 contract.
     *
     * @param name The name to set in the ERC721 contract.
     * @param symbol The symbol to set in the ERC721 contract.
     */
    function _initialize(
		string calldata name, 
		string calldata symbol,
		uint32 cooldownBlocks
	) 
		internal 
	{
        BardsNFTBase._initialize(name, symbol);
		_setCooldownBlocks(cooldownBlocks);
    }

	/**
     * @notice See {IBardsCurationBase-sellerFundsRecipientsOf}
     */
	function sellerFundsRecipientsOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (address[] memory) 
	{
		address[] memory sellerFundsRecipients = _curationData[tokenId].sellerFundsRecipients;
		return sellerFundsRecipients;
	}

	/**
     * @notice See {IBardsCurationBase-sellerFundsRecipientsOf}
     */
	function curationFundsRecipientsOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (uint256[] memory) 
	{
		uint256[] memory curationFundsRecipients = _curationData[tokenId].curationFundsRecipients;
		return curationFundsRecipients;
	}

	/**
     * @notice See {IBardsCurationBase-sellerBpsesOf}
     */
	function sellerFundsBpsesOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (uint32[] memory) 
	{
		uint32[] memory sellerFundsBpses = _curationData[tokenId].sellerFundsBpses;
		return sellerFundsBpses;
	}

	/**
     * @notice See {IBardsCurationBase-curationFundsBpsesOf}
     */
	function curationFundsBpsesOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (uint32[] memory) 
	{
		uint32[] memory curationFundsBpses = _curationData[tokenId].curationFundsBpses;
		return curationFundsBpses;
	}

	/**
     * @notice See {IBardsCurationBase-curationBpsOf}
     */
    function curationBpsOf(uint256 tokenId) 
		external 
		view 
		virtual 
		override 
		returns (uint32) {
			uint32 curationBps = _curationData[tokenId].curationBps;
			require(curationBps <= Constants.MAX_BPS, 'curationBpsOf must set bps <= 100%');
			return curationBps;
    	}

	/**
     * @notice See {IBardsCurationBase-stakingBpsOf}
     */
    function stakingBpsOf(uint256 tokenId) 
		external 
		view 
		virtual 
		override 
		returns (uint32) {
			uint32 stakingBps = _curationData[tokenId].stakingBps;
			require(stakingBps <= Constants.MAX_BPS, 'stakingBps must set bps <= 100%');
			return stakingBps;
   	}

	    /**
     * @notice See {IBardsCurationBase-curationDataOf}
     */
    function curationDataOf(uint256 tokenId)
        external
        view
        virtual
        override
        returns (DataTypes.CurationData memory)
	{
		// if (tokenContract == address(this)){
		// 	require(_exists(tokenId), 'ERC721: token data query for nonexistent token');
		// }
		return _curationData[tokenId];
		}

    /**
     * @notice Internal: Set the time in blocks an curator needs to wait to change curation parameters.
     * @param _blocks Number of blocks to set the cuation parameters cooldown period
     */
    function _setCooldownBlocks(
        uint32 _blocks
    ) 
        internal 
    {
        uint32 prevCooldownBlocks = _cooldownBlocks;
        _cooldownBlocks = _blocks;
        emit Events.CooldownBlocksUpdated(
            prevCooldownBlocks,
            _blocks,
            block.timestamp
        );
    }

	/**
	 * @notice see {IBardsCurationBase-getCurationFeeAmount}
	 */
	function getCurationFeeAmount(uint256 tokenId, uint256 amount)
        external 
        view
        virtual
        override
        returns (uint256 feeAmount) {
			return (amount * _curationData[tokenId].curationBps) / Constants.MAX_BPS;
		}

	/**
	 * @notice see {IBardsCurationBase-getCurationFeeAmount}
	 */
	function getStakingFeeAmount(uint256 tokenId, uint256 amount) 
		external 
        view
        virtual
        override
        returns (uint256 feeAmount) {
			return (amount * _curationData[tokenId].curationBps) / Constants.MAX_BPS;
		}
}