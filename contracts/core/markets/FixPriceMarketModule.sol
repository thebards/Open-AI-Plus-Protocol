// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '../../interfaces/markets/IMarketModule.sol';
import '../../interfaces/curations/IBardsCurationBase.sol';
import '../../utils/DataTypes.sol';
import '../../utils/Errors.sol';
import './MarketModuleBase.sol';
import '../../utils/Constants.sol';
import '../trades/FeePayout.sol';

/**
 * @title FixPriceMarketModule
 * 
 * @author Thebards Protocol
 * 
 * @notice This module allows sellers to list an owned ERC-721 token for sale for a given price in a given currency, 
 * and allows buyers to purchase from those asks.
 */
contract FixPriceMarketModule is MarketModuleBase, FeePayout, IMarketModule {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
	// tokenContract address -> tokenId -> market data
	mapping(address => mapping(uint256 => DataTypes.FixPriceMarketData)) internal _marketMetaData;

    constructor(
        address _hub, 
        address _wethAddress, 
        address _royaltyEngine, 
        address _bardsDaoData,
        address _minter
    ) MarketModuleBase(_bardsDaoData, _minter) FeePayout(_hub, _wethAddress, _royaltyEngine) {}

	/**
     * @dev See {IMarketModule-initializeModule}
     */
	function initializeModule(
		address tokenContract,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes memory) {
		(   
            address seller,
            uint256 price,
            address currency,
            address treasury
        ) = abi.decode(
            data, 
            (address, uint256, address, address)
        );

        if (!isCurrencyWhitelisted(currency) || price == 0) revert Errors.InitParamsInvalid();
		
        if (price == 0) revert Errors.InitParamsInvalid();

        _marketMetaData[tokenContract][tokenId].price = price;
        _marketMetaData[tokenContract][tokenId].currency = currency;

        return data;
	}

	/**
     * @dev See {IMarketModule-buy}
     */
	function buy(
        address buyer,
        uint256 curationId,
		address tokenContract,
        uint256 tokenId,
        uint256[] memory curationIds,
        address[] memory allocationIds
    ) external override {
        // Royalty Payout + Protocol Fee + Curation Fees + staking fees + seller fees

        // The price and currency of NFT.
        DataTypes.FixPriceMarketData memory marketData = _marketMetaData[tokenContract][tokenId];

        // Ensure ETH/ERC-20 payment from buyer is valid and take custody
        _handleIncomingTransfer(buyer, marketData.price, marketData.currency, stakingAddress);

        // Payout respective parties, ensuring royalties are honored
        (uint256 remainingProfit, ) = _handleRoyaltyPayout(
            tokenContract, 
            tokenId, 
            marketData.price, 
            marketData.currency, 
            Constants.USE_ALL_GAS_FLAG
        );

        // Payout protocol fee
        uint256 protocolFee = getFeeAmount(remainingProfit);
        address protocolTreasury = getTreasury();
        remainingProfit = _handleProtocolFeePayout(
            remainingProfit,
            marketData.currency, 
            protocolFee, 
            protocolTreasury
        );

        // Transfer remaining ETH/ERC-20 to seller
        // 1) when the NFT if minted by TheBards HUB, distribute profits proportionally to sellers.
        // 2) or, pay directly to the designated seller.
        if (tokenContract == HUB){
            // The fee split setting of curation.
		    DataTypes.CurationData memory curationData = IBardsCurationBase(tokenContract).curationDataOf(curationId);
            // collect curation
            uint256 curationFee = remainingProfit.mul(uint256(curationData.curationBps)).div(Constants.MAX_BPS);
            remainingProfit -= curationFee;
            _handleCurationsPayout(
                tokenContract, 
                tokenId,
                curationFee,
                marketData.currency,
                curationIds,
                allocationIds
            );
            // collect staking
            uint256 stakingFee = remainingProfit.mul(uint256(curationData.stakingBps)).div(Constants.MAX_BPS);
            remainingProfit -= stakingFee;
            _handleStakingPayout(
                curationId,
                marketData.currency,
                stakingFee
            );

            // payout for sellers
            _handleSellersSplitPayout(
                tokenContract, 
                tokenId,
                remainingProfit,
                marketData.currency,
                curationData.sellerFundsRecipients,
                curationData.sellerBpses
            );
        }else{
            // using default curation and staking bps setting.
            // payout curation
            uint256 curationFee = remainingProfit.mul(uint256(getDefaultCurationBps())).div(Constants.MAX_BPS);
            remainingProfit -= curationFee;
            _handleCurationsPayout(
                tokenContract, 
                tokenId,
                curationFee,
                marketData.currency,
                curationIds
            );

            _handlePayout(
                marketData.treasury, 
                remainingProfit, 
                marketData.currency, 
                Constants.USE_ALL_GAS_FLAG
            );
        }
        
        // Transfer NFT to buyer
        IERC721(tokenContract).safeTransferFrom(marketData.seller, buyer, tokenId);

        delete _marketMetaData[tokenContract][tokenId];
	}

}