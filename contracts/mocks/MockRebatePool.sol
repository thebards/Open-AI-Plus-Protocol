// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

import "../utils/Rebates.sol";
import "../utils/Cobbs.sol";
import "../utils/DataTypes.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Mock contract used for testing rebates
contract MockRebatePool {
    using Rebates for DataTypes.RebatePool;
    using SafeMath for uint256;

    // -- State --
    uint32 public alphaNumerator;
    uint32 public alphaDenominator;

    DataTypes.RebatePool rebatePool;

    // -- Events --
    event Redeemed(uint256 value);

    // Set the alpha for rebates
    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external {
        rebatePool.init(_alphaNumerator, _alphaDenominator);
    }

    // Add fees and stake to the rebate pool

	function add(
        address _currency,
        uint256 _fees,
        uint256 _effectiveAllocationStake
    ) external {
        rebatePool.addToPool(
			_currency,
			_fees,
			_effectiveAllocationStake
		);
    }

    // Remove rewards from rebate pool
    function pop(
		address _currency,
        uint256 _fees,
        uint256 _effectiveAllocationStake
	) external returns (uint256) {
        uint256 value = rebatePool.redeem(
			_currency,
			_fees,
			_effectiveAllocationStake
		);
        emit Redeemed(value);
        return value;
    }

    function getUnclaimedRewards(
        address _currency
    ) external view returns (uint256) {
        uint256 unclaimedFees = rebatePool.fees.fees[_currency].sub(rebatePool.claimedRewards.fees[_currency]);
        return unclaimedFees;
    }

    // Stub to test the cobb-douglas formula directly
    function cobbDouglas(
        uint256 _totalRewards,
        uint256 _fees,
        uint256 _totalFees,
        uint256 _stake,
        uint256 _totalStake,
        uint32 _alphaNumerator,
        uint32 _alphaDenominator
    ) external pure returns (uint256) {
        if (_totalFees == 0 || _totalStake == 0) {
            return 0;
        }

        return
            LibCobbDouglas.cobbDouglas(
                _totalRewards,
                _fees,
                _totalFees,
                _stake,
                _totalStake,
                _alphaNumerator,
                _alphaDenominator
            );
    }
}