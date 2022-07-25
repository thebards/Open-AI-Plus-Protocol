// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '../../interfaces/curation/IBardsCurationBase.sol';
import '../NFTs/BardsNFTBase.sol';
import '../../utils/Constants.sol';
import '../../utils/Events.sol';
import '../../utils/MathUtils.sol';


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
     * @dev ERC-721 token contract => ERC-721 token id => Curation
	 */
    mapping(address => mapping(uint256 => CurationData)) private _curationData;

	/**
     * @dev See {IBardsCurationBase-createCuration}
     */
	function createCuration(DataTypes.CreateCurationData calldata _vars)
		external
		override
		nonReentrant {
			address tokenOwner = IERC721(_vars.tokenContract).ownerOf(_vars.tokenId);

			require(
				msg.sender == tokenOwner || IERC721(_vars._tokenContract).isApprovedForAll(tokenOwner, msg.sender),
				"Creating curation must be token owner or operator"
			);
			require(
				_vars.curationData.sellers.length == _vars.curationData.sellerFundsRecipients.length && 
				_vars.curationData.sellers.length == _vars.curationData.sellerBpses.length, 
				"Sellers, sellerFundsRecipients, and sellerBpses must have same length."
			);
			require(
				MathUtils.sum(_vars.curationData.sellerBpses) == Constants.MAX_BPS, 
				"Sellers fee bps must be equal to 10000."
			);
			require(
				_vars.curationData.curationBps + _vars.curationData.stakingBps <= Constants.MAX_BPS, 
				"curationBps + stakingBps <= 100%"
			);

			_curationData[_vars.tokenContract][_vars.tokenId] = DataTypes.CurationData({
				sellers: _vars.curationData.sellers,
				sellerFundsRecipients: _vars.curationData.sellerFundsRecipients,
				sellerBpses: _vars.curationData.sellerBpses,
				curationBps: _vars.curationData.curationBps,
				stakingBps: _vars.curationData.stakingBps
			});
			
			emit CurationCreated(_vars.tokenContract, _vars.tokenId, _curationData[_vars.tokenContract][_vars.tokenId]);
		}

	/**
     * @dev See {IBardsCurationBase-sellersOf}
     */
	function sellersOf(address tokenContract, uint256 tokenId)
		external
		view
		virtual
		override
		returns (address[] memory) {
			address[] sellers = _curationData[tokenContract][tokenId].sellers;
			return sellers;
		}

	/**
     * @dev See {IBardsCurationBase-sellerFundsRecipientsOf}
     */
	function sellerFundsRecipientsOf(address tokenContract, uint256 tokenId)
		external
		view
		virtual
		override
		returns (address[] memory) {
			address[] sellerFundsRecipients = _curationData[tokenContract][tokenId].sellerFundsRecipients;
			return sellerFundsRecipients;
		}

	/**
     * @dev See {IBardsCurationBase-sellerBpsesOf}
     */
	function sellerBpsesOf(address tokenContract, uint256 tokenId)
		external
		view
		virtual
		override
		returns (uint16[] memory) {
			uint16[] sellerBpses = _curationData[tokenContract][tokenId].sellerBpses;
			return sellerBpses;
		}

	/**
     * @dev See {IBardsCurationBase-curationBpsOf}
     */
    function curationBpsOf(address tokenContract, uint256 tokenId) 
		external 
		view 
		virtual 
		override 
		returns (uint16) {
			uint16 curationBps = _curationData[tokenContract][tokenId].curationBps;
			require(curationBps <= Constants.MAX_BPS, 'curationBpsOf must set bps <= 100%');
			return curationBps;
    	}

	/**
     * @dev See {IBardsCurationBase-stakingBpsOf}
     */
    function stakingBpsOf(address tokenContract, uint256 tokenId) 
		external 
		view 
		virtual 
		override 
		returns (uint16) {
			uint16 stakingBps = _curationData[tokenContract][tokenId].stakingBps;
			require(stakingBps <= Constants.MAX_BPS, 'stakingBps must set bps <= 100%');
			return stakingBps;
   		}

	    /**
     * @dev See {IBardsCurationBase-curationDataOf}
     */
    function curationDataOf(address tokenContract, uint256 tokenId)
        external
        view
        virtual
        override
        returns (CurationData memory){
			if (tokenContract == address(this)){
				require(_exists(tokenId), 'ERC721: token data query for nonexistent token');
			}
			return _curationData[tokenContract][tokenId];
   		 }

	/**
     * @dev See {IBardsCurationBase-setSellersParams}.
     */
	function setSellersParams(address tokenContract, uint256 tokenId, address[] calldata sellers) 
		external 
		virtual 
		override {
			_curationData[tokenContract][tokenId].sellers = sellers;

			emit Events.CurationSellersUpdated(tokenContract, tokenId, sellers, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setSellerFundsRecipientsParams}.
     */
	function setSellerFundsRecipientsParams(address tokenContract, uint256 tokenId, address[] calldata sellerFundsRecipients) 
		external 
		virtual 
		override {
			_curationData[tokenContract][tokenId].sellerFundsRecipients = sellerFundsRecipients;

			emit Events.CurationSellerFundsRecipientsUpdated(tokenContract, tokenId, sellerFundsRecipients, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setSellerBpsesParams}.
     */
	function setSellerBpsesParams(address tokenContract, uint256 tokenId, uint16[] calldata sellerBpses) 
		external 
		virtual 
		override {
			_curationData[tokenContract][tokenId].sellerBpses = sellerBpses;

			emit Events.CurationSellerBpsesUpdated(tokenContract, tokenId, sellerBpses, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setCurationFeeParams}.
     */
	function setCurationBpsParams(address tokenContract, uint256 tokenId, uint16 curationBps) 
		external 
		virtual 
		override {
			require(curationBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

			_curationData[tokenContract][tokenId].curationBps = curationBps;

			emit Events.CurationBpsUpdated(tokenContract, tokenId, curationBps, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setStakingBpsParams}.
     */
	function setStakingBpsParams(address tokenContract, uint256 tokenId, uint16 stakingBps) 
		external 
		virtual 
		override {
			require(stakingBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

			_curationData[tokenContract][tokenId].stakingBps = stakingBps;

			emit Events.StakingBpsUpdated(tokenContract, tokenId, stakingBps, block.timestamp);
		}

	/**
     * @dev See {IBardsCurationBase-setBpsParams}.
     */
	function setBpsParams(address tokenContract, uint256 tokenId, uint16 curationBps, uint16 stakingBps) 
		external 
		virtual 
		override {
			require(curationBps + stakingBps <= Constants.MAX_BPS, 'curationBps + stakingBps <= 100%');
			
			_curationData[tokenContract][tokenId].curationBps = curationBps;
			emit Events.CurationBpsUpdated(tokenContract, tokenId, curationBps, block.timestamp);

			_curationData[tokenContract][tokenId].stakingBps = stakingBps;
			emit Events.StakingBpsUpdated(tokenContract, tokenId, stakingBps, block.timestamp);
		}

	/**
	 * @dev see {IBardsCurationBase-getCurationFeeAmount}
	 */
	function getCurationFeeAmount(address tokenContract, uint256 tokenId, uint256 amount)
        external 
        view
        virtual
        override
        returns (uint256 feeAmount) {
			return (amount * curationBpsOf(tokenContract, tokenId)) / Constants.MAX_BPS;
		}

	/**
	 * @dev see {IBardsCurationBase-getCurationFeeAmount}
	 */
	function getStakingFeeAmount(address tokenContract, uint256 tokenId, uint256 amount) 
		external 
        view
        virtual
        override
        returns (uint256 feeAmount) {
			return (amount * curationBpsOf(tokenContract, tokenId)) / Constants.MAX_BPS;
		}
}