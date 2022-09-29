// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IMarketModule} from '../../interfaces/markets/IMarketModule.sol';
import {IBardsHub} from '../../interfaces/IBardsHub.sol';
import {IBardsCurationBase} from '../../interfaces/curations/IBardsCurationBase.sol';
import {IProgrammableMinter} from '../../interfaces/minters/IProgrammableMinter.sol';
import {MarketModuleBase} from '../trades/MarketModuleBase.sol';
import {DataTypes} from '../../utils/DataTypes.sol';
import {Errors} from '../../utils/Errors.sol';
import {Constants} from '../../utils/Constants.sol';


/**
 * @title FixPriceMarketModule
 * 
 * @author Thebards Protocol
 * 
 * @notice This module allows sellers to list an owned ERC-721 token for sale for a given price in a given currency, 
 * and allows buyers to purchase from those asks.
 */
contract FixPriceMarketModule is MarketModuleBase, IMarketModule {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
	// tokenContract address -> tokenId -> market data
	mapping(address => mapping(uint256 => DataTypes.FixPriceMarketData)) internal _marketMetaData;

    constructor(
        address _hub, 
        address _royaltyEngine
    ) {
        MarketModuleBase._initialize(_hub, _royaltyEngine);
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
        returns (DataTypes.FixPriceMarketData memory)
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
            address currency,
            uint256 price,
            address treasury,
            address minter
        ) = abi.decode(
            data, 
            (address, address, uint256, address, address)
        );

        if (!isCurrencyWhitelisted(currency)) revert Errors.CurrencyNotWhitelisted();
        if (price == 0) revert Errors.ZeroPrice();
        if (minter != address(0) && !bardsHub().isMinterModuleWhitelisted(minter))
            revert Errors.MinterModuleNotWhitelisted();
		
        _marketMetaData[tokenContract][tokenId].seller = seller;
        _marketMetaData[tokenContract][tokenId].price = price;
        _marketMetaData[tokenContract][tokenId].currency = currency;
        _marketMetaData[tokenContract][tokenId].treasury = treasury;
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
        // Royalty Payout + Protocol Fee + Curation Fees + staking fees + seller fees
        address _collector = collector;
        uint256 _curationId = curationId;
        // The price and currency of NFT.
        DataTypes.FixPriceMarketData memory marketData = _marketMetaData[tokenContract][tokenId];

        // Before core logic of  collecting, collect fees to a specific address, 
        // and pay royalties and protocol fees
        uint256 remainingProfit = _beforeCollecting(
            _collector,
            marketData.price, 
            marketData.currency,
            tokenContract,
            tokenId
        );

        // Transfer remaining ETH/ERC-20 to stakeholders.
        uint256 curationFee;
        if (_curationId != 0) {
            // curation meta data
            DataTypes.CurationStruct memory curationStruct = bardsHub().getCuration(_curationId);
            require(curationStruct.tokenContractPointed == tokenContract && curationStruct.tokenIdPointed == tokenId, "When Collecting in fix price market, NFT and curation mismatch");

            // 1) tokenContract == HUB, deal curation.
            // 2) tokenContract != HUB, deal token curated, but using curationBps and stakingBps in curation.

            // The fee split setting of curation.
		    DataTypes.CurationData memory curationData = IBardsCurationBase(HUB).curationDataOf(_curationId);

            // collect curation
            curationFee = remainingProfit.mul(uint256(curationData.curationBps)).div(Constants.MAX_BPS);
            remainingProfit -= curationFee;
            _handleCurationsPayout(
                tokenContract, 
                tokenId,
                curationFee,
                marketData.currency,
                curationIds
            );
            // collect staking
            uint256 stakingFee = remainingProfit.mul(uint256(curationData.stakingBps)).div(Constants.MAX_BPS);
            remainingProfit -= stakingFee;
            _handleStakingPayout(
                _curationId,
                marketData.currency,
                stakingFee
            );

            // payout for sellers
            _handleSellersSplitPayout(
                tokenContract, 
                tokenId,
                remainingProfit,
                marketData.currency,
                _curationId
            );

        } else {
            // Just listed on the Decentralized Market, not curated.
            // using default curation and staking bps setting.

            require(tokenContract != HUB, "Collecting non-HUB NFTs");
            // payout curation
            curationFee = remainingProfit.mul(uint256(getDefaultCurationBps())).div(Constants.MAX_BPS);
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
        
        (
            address retTokenContract,
            uint256 retTokenId
        ) = IProgrammableMinter(marketData.minter).mint(
            collectMetaData
        );

        delete _marketMetaData[tokenContract][tokenId];

        return (retTokenContract, retTokenId);
	}

}