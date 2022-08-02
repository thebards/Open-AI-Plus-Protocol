// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/markets/IMarketModule.sol';
import '../../interfaces/govs/IBardsDaoData.sol';
import '../../utils/Errors.sol';
import '../../utils/Events.sol';
import '../../utils/DataTypes.sol';

abstract contract MarketModuleBase {
	address public immutable _bardsDaoData;

    constructor(address bardsDaoData) {
        if (bardsDaoData == address(0)) revert Errors.InitParamsInvalid();
        _bardsDaoData = bardsDaoData;
        emit Events.MarketModuleBaseConstructed(_bardsDaoData, block.timestamp);
    }

    function _currencyWhitelisted(address currency) 
		internal 
		view 
		returns (bool) {
        	return IBardsDaoData(_bardsDaoData).isCurrencyWhitelisted(currency);
    }

    function _protocolFeeSetting()
		internal 
		view 
		returns (DataTypes.ProtocolFeeSetting memory) {
        	return IBardsDaoData(_bardsDaoData).getProtocolFeeSetting();
    }

	function _protocolFee()
		internal
		view
		returns (uint16) {
			return IBardsDaoData(_bardsDaoData).getProtocolFee();
	}

	function _treasury()
		internal
		view
		returns (address){
			return IBardsDaoData(_bardsDaoData).getTreasury();
		}
}