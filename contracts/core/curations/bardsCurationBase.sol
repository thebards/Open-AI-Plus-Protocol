// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '../../interfaces/curations/IBardsCurationBase.sol';
import '../NFTs/BardsNFTBase.sol';
import '../../utils/Constants.sol';
import '../../utils/Events.sol';
import '../../utils/MathUtils.sol';
import '../../utils/DataTypes.sol';

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
    mapping(uint256 => DataTypes.CurationData) private _curationData;

	/**
     * @notice See {IBardsCurationBase-createCuration}
     */
	function initializeCuration(DataTypes.InitializeCurationData memory _vars)
		public
		override
		{
			// address tokenOwner = IERC721(_vars.tokenContract).ownerOf(_vars.tokenId);

			// require(
			// 	msg.sender == tokenOwner || IERC721(_vars._tokenContract).isApprovedForAll(tokenOwner, msg.sender),
			// 	"Creating curation must be token owner or operator"
			// );
			(
				address[] memory sellerFundsRecipients,
				uint256[] memory curationFundsRecipients,
				uint32[] memory sellerFundsBpses,
				uint32[] memory curationFundsBpses,
				uint32 curationBps,
				uint32 stakingBps
			) = abi.decode(
					_vars.curationData, 
					(address[], uint256[], uint32[], uint32[], uint32, uint32)
				);

			require(
				sellerFundsBpses.length == sellerFundsRecipients.length, 
				"sellerFundsRecipients and sellerFundsBpses must have same length."
			);
			require(
				curationFundsRecipients.length == curationFundsBpses.length, 
				"curationFundsRecipients and curationFundsBpses must have same length."
			);
			require(
				MathUtils.sum(MathUtils.uint32To256Array(sellerFundsBpses)) + 
				MathUtils.sum(MathUtils.uint32To256Array(curationFundsBpses)) == Constants.MAX_BPS, 
				"The sum of sellerFundsBpses and curationFundsBpses must be equal to 1000000."
			);
			require(
				curationBps + stakingBps <= Constants.MAX_BPS, 
				"curationBps + stakingBps <= 100%"
			);

			_curationData[_vars.tokenId] = DataTypes.CurationData({
				sellerFundsRecipients: sellerFundsRecipients,
				curationFundsRecipients: curationFundsRecipients,
				sellerFundsBpses: sellerFundsBpses,
				curationFundsBpses: curationFundsBpses,
				curationBps: curationBps,
				stakingBps: stakingBps
			});
			
			emit Events.CurationInitialized(
				_vars.tokenId, 
				_vars.curationData, 
				block.timestamp
			);
		}

	/**
     * @notice See {IBardsCurationBase-sellerFundsRecipientsOf}
     */
	function sellerFundsRecipientsOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (address[] memory) {
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
		returns (uint256[] memory) {
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
        returns (DataTypes.CurationData memory){
			// if (tokenContract == address(this)){
			// 	require(_exists(tokenId), 'ERC721: token data query for nonexistent token');
			// }
			return _curationData[tokenId];
   		 }

	/**
     * @notice See {IBardsCurationBase-setSellerFundsRecipientsParams}.
     */
	function setSellerFundsRecipientsParams(uint256 tokenId, address[] calldata sellerFundsRecipients) 
		external 
		virtual 
		override 
	{
		_curationData[tokenId].sellerFundsRecipients = sellerFundsRecipients;

		emit Events.CurationSellerFundsRecipientsUpdated(tokenId, sellerFundsRecipients, block.timestamp);
	}

	/**
     * @notice See {IBardsCurationBase-setCurationFundsRecipientsParams}.
     */
	function setCurationFundsRecipientsParams(uint256 tokenId, uint256[] calldata curationFundsRecipients) 
		external 
		virtual 
		override 
	{
		_curationData[tokenId].curationFundsRecipients = curationFundsRecipients;

		emit Events.CurationFundsRecipientsUpdated(
			tokenId, 
			curationFundsRecipients, 
			block.timestamp
		);
	}

	/**
     * @notice See {IBardsCurationBase-setSellerFundsBpsesParams}.
     */
	function setSellerFundsBpsesParams(uint256 tokenId, uint32[] calldata sellerFundsBpses) 
		external 
		virtual 
		override 
	{
		_curationData[tokenId].sellerFundsBpses = sellerFundsBpses;

		emit Events.CurationSellerFundsBpsesUpdated(
			tokenId, 
			sellerFundsBpses, 
			block.timestamp
		);
	}

	/**
     * @notice See {IBardsCurationBase-setCurationFundsBpsesParams}.
     */
	function setCurationFundsBpsesParams(uint256 tokenId, uint32[] calldata curationFundsBpses) 
		external 
		virtual 
		override 
	{
		_curationData[tokenId].curationFundsBpses = curationFundsBpses;

		emit Events.CurationFundsBpsesUpdated(
			tokenId, 
			curationFundsBpses, 
			block.timestamp
		);
	}

	/**
     * @notice See {IBardsCurationBase-setCurationFeeParams}.
     */
	function setCurationBpsParams(uint256 tokenId, uint32 curationBps) 
		external 
		virtual 
		override {
			require(curationBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

			_curationData[tokenId].curationBps = curationBps;

			emit Events.CurationBpsUpdated(tokenId, curationBps, block.timestamp);
		}

	/**
     * @notice See {IBardsCurationBase-setStakingBpsParams}.
     */
	function setStakingBpsParams(uint256 tokenId, uint32 stakingBps) 
		external 
		virtual 
		override {
			require(stakingBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

			_curationData[tokenId].stakingBps = stakingBps;

			emit Events.StakingBpsUpdated(tokenId, stakingBps, block.timestamp);
		}

	/**
     * @notice See {IBardsCurationBase-setBpsParams}.
     */
	function setBpsParams(uint256 tokenId, uint32 curationBps, uint32 stakingBps) 
		external 
		virtual 
		override {
			require(curationBps + stakingBps <= Constants.MAX_BPS, 'curationBps + stakingBps <= 100%');
			
			_curationData[tokenId].curationBps = curationBps;
			emit Events.CurationBpsUpdated(tokenId, curationBps, block.timestamp);

			_curationData[tokenId].stakingBps = stakingBps;
			emit Events.StakingBpsUpdated(tokenId, stakingBps, block.timestamp);
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