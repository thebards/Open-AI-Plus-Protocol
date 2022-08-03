// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
     * @dev Casting uint16[] to uint256[]
     */
    function uint16To256Array(uint16[] memory arr) internal pure returns (uint256[] memory) {
        uint256[] memory res; 
        if (arr.length == 0)
            return res;
            
        res = new uint[](arr.length);
        for(uint256 i = 0; i < arr.length; i++){
            res[i] = uint256(arr[i]);
        }
        return res;
    }
}