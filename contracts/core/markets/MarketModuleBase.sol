// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '../../interfaces/markets/IMarketModule.sol';
import '../govs/ContractRegistrar.sol';
import '../trades/FeePayout.sol';
import '../../utils/Errors.sol';
import '../../utils/Events.sol';
import '../../utils/DataTypes.sol';

abstract contract MarketModuleBase is FeePayout {
	address public minter;

    function _initialize(
        address _hub, 
        address _wethAddress,
        address _royaltyEngine,
        address _minter
	) 
		internal 
	{
        if (_hub == address(0) || _minter == address(0)) revert Errors.InitParamsInvalid();
		minter = _minter;
		FeePayout._initialize(_hub, _wethAddress, _royaltyEngine);
        emit Events.MarketModuleBaseConstructed(_minter, block.timestamp);
    }

    function isCurrencyWhitelisted(address currency)
		internal 
		view 
		returns (bool) {
        	return bardsDataDao().isCurrencyWhitelisted(currency);
    }

    function getProtocolFeeSetting()
		internal 
		view 
		returns (DataTypes.ProtocolFeeSetting memory) {
        	return bardsDataDao().getProtocolFeeSetting();
    }

	function getProtocolFee()
		internal
		view
		returns (uint32) {
			return bardsDataDao().getProtocolFee();
	}

	function getDefaultCurationBps()
		internal
		view
		returns (uint32) {
			return bardsDataDao().getDefaultCurationBps();
	}

	function getDefaultStakingBps()
		internal
		view
		returns (uint32) {
			return bardsDataDao().getDefaultStakingBps();
	}

	function getTreasury()
		internal
		view
		returns (address){
			return bardsDataDao().getTreasury();
		}

	function getFeeAmount(uint256 _amount)
		internal
		view
		returns (uint256) {
			return bardsDataDao().getFeeAmount(_amount);
		}
}