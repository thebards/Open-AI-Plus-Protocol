// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './DataTypes.sol';
import './TokenUtils.sol';
import "hardhat/console.sol";

library MultiCurrencyFeesUtils {
    using SafeMath for uint256;
    using MultiCurrencyFeesUtils for DataTypes.MultiCurrencyFees;

	function clear(DataTypes.MultiCurrencyFees storage _fees) internal {
		if (_fees.currencies.length == 0){
			return;
		}
		_fees.totalShare = 0;
		uint256 j = _fees.currencies.length - 1;
		while(j >= 0){
			address _curCurrency = _fees.currencies[_fees.currencies.length - 1];
			delete _fees.fees[_curCurrency];
			_fees.currencies.pop();
			j--;
		}
	}

	/**
	 * @notice Add fees
	 */
	function tryInsertCurrencyFees(DataTypes.MultiCurrencyFees storage _fees, address _newCurrency, uint256 _amount) internal {
		if (_fees.fees[_newCurrency] > 0){
			_fees.fees[_newCurrency] = _fees.fees[_newCurrency].add(_amount);
			return;
		}
		_fees.fees[_newCurrency] = _amount;
		bool flag = false;
		for(uint256 i = 0; i < _fees.currencies.length; i ++){
			if (_fees.currencies[i] == _newCurrency){
				flag = true;
				break;
			}
		}
		if (!flag){
			_fees.currencies.push(_newCurrency);
		}
	}

	/**
	 * @notice Withdraw all fees
	 */
	function withdraw(
		DataTypes.MultiCurrencyFees storage _fees, 
		address _from, 
		address _to
	) 
		internal 
	{
		for(uint256 i = 0; i < _fees.currencies.length; i++){
            address _currency = _fees.currencies[i];
			TokenUtils.transfer(IERC20(_currency), _from, _fees.fees[_currency], _to);
		}
		
	}

}