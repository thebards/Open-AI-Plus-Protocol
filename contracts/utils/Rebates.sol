// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.12;
// pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {LibCobbDouglas} from './Cobbs.sol';
import {DataTypes} from './DataTypes.sol';
import {MultiCurrencyFeesUtils} from './MultiCurrencyFeesUtils.sol';

/**
 * @title A collection of data structures and functions to manage Rebates
 *        Used for low-level state changes, require() conditions should be evaluated
 *        at the caller function scope.
 */
library Rebates {
    using SafeMath for uint256;
    using Rebates for DataTypes.RebatePool;
    using MultiCurrencyFeesUtils for DataTypes.MultiCurrencyFees;

    /**
     * @notice Init the rebate pool with the rebate ratio.
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function init(
        DataTypes.RebatePool storage pool,
        uint32 _alphaNumerator,
        uint32 _alphaDenominator
    ) internal {
        pool.alphaNumerator = _alphaNumerator;
        pool.alphaDenominator = _alphaDenominator;
    }

    /**
     * @notice Return true if the rebate pool was already initialized.
     */
    function exists(DataTypes.RebatePool storage pool) internal view returns (bool) {
        return pool.unclaimedAllocationsCount > 0;
    }

    /**
     * @notice Return the amount of unclaimed fees, given currency .
     */
    function unclaimedFees(
        DataTypes.RebatePool storage pool, 
        address _currency
    ) internal view returns (uint256) {
        return pool.fees.fees[_currency].sub(pool.claimedRewards.fees[_currency]);
    }

    /**
     * @notice Deposit tokens into the rebate pool.
     * 
     * @param _currency Currency of deposit token
     * @param _fees Amount of fees collected in tokens
     * @param _effectiveAllocationStake Effective stake allocated by delegator for a period of epochs
     */
    function addToPool(
        DataTypes.RebatePool storage pool,
        address _currency,
        uint256 _fees,
        uint256 _effectiveAllocationStake
    ) internal {
        pool.fees.tryInsertCurrencyFees(_currency, _fees);
        pool.effectiveAllocationStake[_currency] = pool.effectiveAllocationStake[_currency].add(
            _effectiveAllocationStake
        );
        pool.unclaimedAllocationsCount += 1;
    }

    /**
     * @notice Redeem tokens from the rebate pool.
     * 
     * @param _currency Currency of deposit token
     * @param _fees Amount of fees collected in tokens
     * @param _effectiveAllocationStake Effective stake allocated by delegator for a period of epochs
     * @return Amount of reward tokens according to Cobb-Douglas rebate formula
     */
    function redeem(
        DataTypes.RebatePool storage pool,
        address _currency,
        uint256 _fees,
        uint256 _effectiveAllocationStake
    ) internal returns (uint256) {
        uint256 rebateReward = 0;

        // Calculate the rebate rewards for the delegator
        if (pool.fees.fees[_currency] > 0 && pool.effectiveAllocationStake[_currency] > 0) {
            rebateReward = LibCobbDouglas.cobbDouglas(
                pool.fees.fees[_currency], // totalRewards
                _fees,
                pool.fees.fees[_currency],
                _effectiveAllocationStake,
                pool.effectiveAllocationStake[_currency],
                pool.alphaNumerator,
                pool.alphaDenominator
            );

            // Under NO circumstance we will reward more than total fees in the pool
            uint256 _unclaimedFees = pool.unclaimedFees(_currency);
            if (rebateReward > _unclaimedFees) {
                rebateReward = _unclaimedFees;
            }
        }

        // Update pool state
        pool.unclaimedAllocationsCount -= 1;
        pool.claimedRewards.fees[_currency] = pool.claimedRewards.fees[_currency].add(rebateReward);

        return rebateReward;
    }
}