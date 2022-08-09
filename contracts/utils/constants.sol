// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Constants{
	uint16 constant MAX_BPS = 10000;
	uint8 constant MAX_HANDLE_LENGTH = 31;
	/// @dev The indicator to pass all remaining gas when paying out royalties
    uint256 constant USE_ALL_GAS_FLAG = 0;
}