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
     * @dev ERC-721 token id => Curation
	 */
    mapping(uint256 => DataTypes.CurationData) private _curationData;

	/**
     * @dev See {IBardsCurationBase-createCuration}
     */
	function initializeCuration(DataTypes.InitializeCurationData calldata _vars)
		external
		override
		nonReentrant {
			// address tokenOwner = IERC721(_vars.tokenContract).ownerOf(_vars.tokenId);

			// require(
			// 	msg.sender == tokenOwner || IERC721(_vars._tokenContract).isApprovedForAll(tokenOwner, msg.sender),
			// 	"Creating curation must be token owner or operator"
			// );
			(
				address[] sellers,
				address[] sellerFundsRecipients,
				uint16[] sellerBpses,
				uint16 curationBps,
				uint16 stakingBps
			) = abi.decode(_vars.curationData, (address[], address[], uint16[], uint16, uint16));

			require(
				sellers.length == sellerFundsRecipients.length && 
				sellers.length == sellerBpses.length, 
				"Sellers, sellerFundsRecipients, and sellerBpses must have same length."
			);
			require(
				MathUtils.sum(sellerBpses) == Constants.MAX_BPS, 
				"Sellers fee bps must be equal to 10000."
			);
			require(
				curationBps + stakingBps <= Constants.MAX_BPS, 
				"curationBps + stakingBps <= 100%"
			);

			_curationData[_vars.tokenId] = DataTypes.CurationData({
				sellers: sellers,
				sellerFundsRecipients: sellerFundsRecipients,
				sellerBpses: sellerBpses,
				curationBps: curationBps,
				stakingBps: stakingBps
			});
			
			emit CurationInitialized(_vars.tokenId, _vars.curationData, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-sellersOf}
     */
	function sellersOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (address[] memory) {
			address[] sellers = _curationData[tokenId].sellers;
			return sellers;
		}

	/**
     * @dev See {IBardsCurationBase-sellerFundsRecipientsOf}
     */
	function sellerFundsRecipientsOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (address[] memory) {
			address[] sellerFundsRecipients = [tokenId].sellerFundsRecipients;
			return sellerFundsRecipients;
		}

	/**
     * @dev See {IBardsCurationBase-sellerBpsesOf}
     */
	function sellerBpsesOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (uint16[] memory) {
			uint16[] sellerBpses = _curationData[tokenId].sellerBpses;
			return sellerBpses;
		}

	/**
     * @dev See {IBardsCurationBase-curationBpsOf}
     */
    function curationBpsOf(uint256 tokenId) 
		external 
		view 
		virtual 
		override 
		returns (uint16) {
			uint16 curationBps = _curationData[tokenId].curationBps;
			require(curationBps <= Constants.MAX_BPS, 'curationBpsOf must set bps <= 100%');
			return curationBps;
    	}

	/**
     * @dev See {IBardsCurationBase-stakingBpsOf}
     */
    function stakingBpsOf(uint256 tokenId) 
		external 
		view 
		virtual 
		override 
		returns (uint16) {
			uint16 stakingBps = _curationData[tokenId].stakingBps;
			require(stakingBps <= Constants.MAX_BPS, 'stakingBps must set bps <= 100%');
			return stakingBps;
   		}

	    /**
     * @dev See {IBardsCurationBase-curationDataOf}
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
     * @dev See {IBardsCurationBase-setSellersParams}.
     */
	function setSellersParams(uint256 tokenId, address[] calldata sellers) 
		external 
		virtual 
		override {
			_curationData[tokenId].sellers = sellers;

			emit Events.CurationSellersUpdated(tokenId, sellers, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setSellerFundsRecipientsParams}.
     */
	function setSellerFundsRecipientsParams(uint256 tokenId, address[] calldata sellerFundsRecipients) 
		external 
		virtual 
		override {
			_curationData[tokenId].sellerFundsRecipients = sellerFundsRecipients;

			emit Events.CurationSellerFundsRecipientsUpdated(tokenId, sellerFundsRecipients, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setSellerBpsesParams}.
     */
	function setSellerBpsesParams(uint256 tokenId, uint16[] calldata sellerBpses) 
		external 
		virtual 
		override {
			_curationData[tokenId].sellerBpses = sellerBpses;

			emit Events.CurationSellerBpsesUpdated(tokenId, sellerBpses, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setCurationFeeParams}.
     */
	function setCurationBpsParams(uint256 tokenId, uint16 curationBps) 
		external 
		virtual 
		override {
			require(curationBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

			_curationData[tokenId].curationBps = curationBps;

			emit Events.CurationBpsUpdated(tokenId, curationBps, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setStakingBpsParams}.
     */
	function setStakingBpsParams(uint256 tokenId, uint16 stakingBps) 
		external 
		virtual 
		override {
			require(stakingBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

			_curationData[tokenId].stakingBps = stakingBps;

			emit Events.StakingBpsUpdated(tokenId, stakingBps, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setBpsParams}.
     */
	function setBpsParams(uint256 tokenId, uint16 curationBps, uint16 stakingBps) 
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
	 * @dev see {IBardsCurationBase-getCurationFeeAmount}
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
	 * @dev see {IBardsCurationBase-getCurationFeeAmount}
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