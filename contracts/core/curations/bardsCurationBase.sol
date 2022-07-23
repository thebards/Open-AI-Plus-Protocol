// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '../../interfaces/curation/IBardsCurationBase.sol';
import '../NFTs/BardsNFTBase.sol';
import '../../utils/constants.sol';
import '../../utils/Events.sol';


/**
 * @title BardsCurationBase
 * @author TheBards Protocol
 *
 * @notice This is an abstract base contract to be inherited by other TheBards Protocol Curations, it includes
 * NFT module and curation fee setting module.
 */
abstract contract BardsCurationBase is IBardsCurationBase, BardsNFTBase {

	// Mapping from token ID to curation Data, this
    // mapping(uint256 => CurationData) private _curationData;
	/// @notice The curation for a given NFT, if one exists
    /// @dev ERC-721 token contract => ERC-721 token id => Curation
    mapping(address => mapping(uint256 => CurationData)) private _curationData;

	/**
     * @dev See {IBardsCurationBase-sellersOf}
     */
	function sellersOf(address tokenContract, uint256 tokenId)
		public
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
		public
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
		public
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
		public 
		view 
		virtual 
		override 
		returns (uint16) {
			uint16 curationBps = _curationData[tokenContract][tokenId].curationBps;
			require(curationBps <= constants.MAX_BPS, 'curationBpsOf must set bps <= 100%');
			return curationBps;
    	}

	/**
     * @dev See {IBardsCurationBase-stakingBpsOf}
     */
    function stakingBpsOf(address tokenContract, uint256 tokenId) 
		public 
		view 
		virtual 
		override 
		returns (uint16) {
			uint16 stakingBps = _curationData[tokenContract][tokenId].stakingBps;
			require(stakingBps <= constants.MAX_BPS, 'stakingBps must set bps <= 100%');
			return stakingBps;
   		}

	    /**
     * @dev See {IBardsCurationBase-curationDataOf}
     */
    function curationDataOf(address tokenContract, uint256 tokenId)
        public
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
		public 
		virtual 
		override {
			_curationData[tokenContract][tokenId].sellers = sellers;

			emit Events.CurationSellersUpdated(tokenContract, tokenId, sellers);
		}

	/**
     * @dev See {IBardsCurationBase-setSellerFundsRecipientsParams}.
     */
	function setSellerFundsRecipientsParams(address tokenContract, uint256 tokenId, address[] calldata sellerFundsRecipients) 
		public 
		virtual 
		override {
			_curationData[tokenContract][tokenId].sellerFundsRecipients = sellerFundsRecipients;

			emit Events.CurationSellerFundsRecipientsUpdated(tokenContract, tokenId, sellerFundsRecipients);
		}

	/**
     * @dev See {IBardsCurationBase-setSellerBpsesParams}.
     */
	function setSellerBpsesParams(address tokenContract, uint256 tokenId, uint16[] calldata sellerBpses) 
		public 
		virtual 
		override {
			_curationData[tokenContract][tokenId].sellerBpses = sellerBpses;

			emit Events.CurationSellerBpsesUpdated(tokenContract, tokenId, sellerBpses);
		}

	/**
     * @dev See {IBardsCurationBase-setCurationFeeParams}.
     */
	function setCurationBpsParams(address tokenContract, uint256 tokenId, uint16 curationBps) 
		public 
		virtual 
		override {
			require(curationBps <= constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

			_curationData[tokenContract][tokenId].curationBps = curationBps;

			emit Events.CurationBpsUpdated(tokenContract, tokenId, curationBps);
		}

	/**
     * @dev See {IBardsCurationBase-setStakingBpsParams}.
     */
	function setStakingBpsParams(address tokenContract, uint256 tokenId, uint16 stakingBps) 
		public 
		virtual 
		override {
			require(stakingBps <= constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

			_curationData[tokenContract][tokenId].stakingBps = stakingBps;

			emit Events.StakingBpsUpdated(tokenContract, tokenId, stakingBps);
		}

	/**
     * @dev See {IBardsCurationBase-setBpsParams}.
     */
	function setBpsParams(address tokenContract, uint256 tokenId, uint16 curationBps, uint16 stakingBps) 
		public 
		virtual 
		override {
			require(curationBps + stakingBps <= constants.MAX_BPS, 'curationBps + stakingBps <= 100%');
			
			_curationData[tokenContract][tokenId].curationBps = curationBps;
			emit Events.CurationBpsUpdated(tokenContract, tokenId, curationBps);

			_curationData[tokenContract][tokenId].stakingBps = stakingBps;
			emit Events.StakingBpsUpdated(tokenContract, tokenId, stakingBps);
		}

	/**
	 * @dev see {IBardsCurationBase-getCurationFeeAmount}
	 */
	function getCurationFeeAmount(address tokenContract, uint256 tokenId, uint256 amount)
        public 
        view
        virtual
        override
        returns (uint256 feeAmount) {
			return (amount * curationBpsOf(tokenContract, tokenId)) / constants.MAX_BPS;
		}

	/**
	 * @dev see {IBardsCurationBase-getCurationFeeAmount}
	 */
	function getStakingFeeAmount(address tokenContract, uint256 tokenId, uint256 amount) 
		public 
        view
        virtual
        override
        returns (uint256 feeAmount) {
			return (amount * curationBpsOf(tokenContract, tokenId)) / constants.MAX_BPS;
		}
}