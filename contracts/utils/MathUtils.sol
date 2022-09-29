// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title MathUtils Library
 * @notice A collection of functions to perform math operations
 */
library MathUtils {
    using SafeMath for uint256;

    /**
     * @dev Calculates the weighted average of two values pondering each of these
     * values based on configured weights. The contribution of each value N is
     * weightN/(weightA + weightB).
     * @param valueA The amount for value A
     * @param weightA The weight to use for value A
     * @param valueB The amount for value B
     * @param weightB The weight to use for value B
     */
    function weightedAverage(
        uint256 valueA,
        uint256 weightA,
        uint256 valueB,
        uint256 weightB
    ) internal pure returns (uint256) {
        return valueA.mul(weightA).add(valueB.mul(weightB)).div(weightA.add(weightB));
    }

    /**
     * @dev Returns the minimum of two numbers.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    /**
     * @dev Returns the difference between two numbers or zero if negative.
     */
    function diffOrZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x.sub(y) : 0;
    }

	/**
	 * @dev Returns the sum of a uint256 array.
	 */
	function sum(uint256[] memory arr) internal pure returns (uint256){
		if (arr.length == 0) return 0;
		
		uint256 i;
  		uint256 _sum = 0;
    
		for(i = 0; i < arr.length; i++)
			_sum = _sum.add(arr[i]);
		return _sum;
	}

    /**
     * @dev Casting uint32[] to uint256[]
     */
    function uint32To256Array(uint32[] memory arr) internal pure returns (uint256[] memory) {
        uint256[] memory res; 
        if (arr.length == 0)
            return res;
            
        res = new uint[](arr.length);
        for(uint256 i = 0; i < arr.length; i++){
            res[i] = uint256(arr[i]);
        }
        return res;
    }

    /**
     * @dev Raises x to the power of n with scaling factor of base.
     * Based on: https://github.com/makerdao/dss/blob/master/src/pot.sol#L81
     * @param x Base of the exponentiation
     * @param n Exponent
     * @param base Scaling factor
     * @return z Exponential of n with base x
     */
    function pow(
        uint256 x,
        uint256 n,
        uint256 base
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := base
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := base
                }
                default {
                    z := x
                }
                let half := div(base, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, base)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}