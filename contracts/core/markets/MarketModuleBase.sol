// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/markets/IMarketModule.sol';
import '../../interfaces/govs/IBardsDaoData.sol';
import '../../utils/Errors.sol';
import '../../utils/Events.sol';
import '../../utils/DataTypes.sol';

abstract contract MarketModuleBase {
	address public immutable _bardsDaoData;
	address public _minter;

    constructor(address bardsDaoData, address minter) {
        if (bardsDaoData == address(0) || minter == address(0)) revert Errors.InitParamsInvalid();
        _bardsDaoData = bardsDaoData;
		_minter = minter;
        emit Events.MarketModuleBaseConstructed(_bardsDaoData, _minter, block.timestamp);
    }

    function isCurrencyWhitelisted(address currency)
		internal 
		view 
		returns (bool) {
        	return IBardsDaoData(_bardsDaoData).isCurrencyWhitelisted(currency);
    }

    function getProtocolFeeSetting()
		internal 
		view 
		returns (DataTypes.ProtocolFeeSetting memory) {
        	return IBardsDaoData(_bardsDaoData).getProtocolFeeSetting();
    }

	function getProtocolFee()
		internal
		view
		returns (uint16) {
			return IBardsDaoData(_bardsDaoData).getProtocolFee();
	}

	function getDefaultCurationBps()
		internal
		view
		returns (uint16) {
			return IBardsDaoData(_bardsDaoData).getDefaultCurationBps();
	}

	function getDefaultStakingBps()
		internal
		view
		returns (uint16) {
			return IBardsDaoData(_bardsDaoData).getDefaultStakingBps();
	}

	function getTreasury()
		internal
		view
		returns (address){
			return IBardsDaoData(_bardsDaoData).getTreasury();
		}

	function getFeeAmount(uint256 _amount)
		internal
		view
		returns (uint256) {
			return IBardsDaoData(_bardsDaoData).getFeeAmount(_amount);
		}
}