// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library Constants{
	uint32 constant MAX_BPS = 1000000; 
	uint8 constant MAX_HANDLE_LENGTH = 31;
	// The indicator to pass all remaining gas when paying out royalties
    uint256 constant USE_ALL_GAS_FLAG = 0;
	// Amount of share you get with your minimum token deposit
    uint256 constant SHARE_PER_MINIMUM_DEPOSIT = 1e18; // 1 signal as 18 decimal number
	uint256 constant MIN_ISSUANCE_RATE = 1e18;
	uint256 constant TOKEN_DECIMALS = 1e18;
	uint256 constant MAX_CURATION_CONTENT_URI_LENGTH = 6000;
}