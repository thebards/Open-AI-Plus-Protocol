// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '../../interfaces/markets/IMarketModule.sol';
import '../../interfaces/curation/IBardsCurationBase.sol';
import '../../utils/DataTypes.sol';
import '../../utils/Errors.sol';
import './MarketModuleBase.sol';
import '../../utils/constants.sol';

contract FixPriceMarketModule is MarketModuleBase, IMarketModule {

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
		address tokenContract,
        uint256 tokenId,
        bytes calldata data
    ) external override {
		uint256 price = _marketMetaData[tokenContract][tokenId].price;
		address currency = _marketMetaData[tokenContract][tokenId].currency;

		DataTypes.CurationData memory curationData = IBardsCurationBase(tokenContract).curationDataOf(tokenContract, tokenId);

		// TODO Royalty Payout + Protocol Fee + Curation Fees + sellers fee

        // protocol fee setting
        (
            address treasury,
            uint16 feeBps
        ) = _protocolFeeSetting();
	}

}