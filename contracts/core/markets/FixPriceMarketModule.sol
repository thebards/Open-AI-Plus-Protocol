// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../../interfaces/markets/IMarketModule.sol';
import '../../interfaces/curations/IBardsCurationBase.sol';
import '../../utils/DataTypes.sol';
import '../../utils/Errors.sol';
import './MarketModuleBase.sol';
import '../../utils/Constants.sol';

contract FixPriceMarketModule is MarketModuleBase, IMarketModule {
    using SafeERC20 for IERC20;
	// tokenContract address -> tokenId -> market data
	mapping(address => mapping(uint256 => DataTypes.FixPriceMarketData)) internal _marketMetaData;

    constructor(address bardsDaoData) MarketModuleBase(bardsDaoData) {}

	/**
     * @dev See {IMarketModule-initializeModule}
     */
	function initializeModule(
		address tokenContract,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes memory) {
		(
            uint256 price,
            address currency
        ) = abi.decode(data, (uint256, address));

        if (!_currencyWhitelisted(currency) || price == 0) revert Errors.InitParamsInvalid();
		
        if (price == 0) revert Errors.InitParamsInvalid();

        _marketMetaData[tokenContract][tokenId].price = price;
        _marketMetaData[tokenContract][tokenId].currency = currency;

        return data;
	}

	/**
     * @dev See {IMarketModule-buy}
     */
	function buy(
        uint256 curationId,
		address tokenContract,
        uint256 tokenId,
        bytes calldata data
    ) external override {

        // The price and currency of NFT.
        DataTypes.FixPriceMarketData memory marketData = _marketMetaData[tokenContract][tokenId];

        // The fee split setting of curation.
		DataTypes.CurationData memory curationData = IBardsCurationBase(tokenContract).curationDataOf(curationId);
        

		// TODO Royalty Payout + Protocol Fee + Curation Fees + staking fees + seller fees

        // protocol fee setting
        DataTypes.ProtocolFeeSetting memory protocolFeeSetting = _protocolFeeSetting();

        delete _marketMetaData[tokenContract][tokenId];
	}

}